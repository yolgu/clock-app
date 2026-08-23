import '../domain/rhythm_settings_draft.dart';
import '../domain/user_preferences.dart';
import 'ports/auto_start_port.dart';
import 'ports/draft_store.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class SaveRhythmSettings {
  const SaveRhythmSettings({
    required this._settingsRepository,
    required this._autoStart,
    required this._preferencesChanged,
    required this._draftStore,
  });

  final SettingsRepository _settingsRepository;
  final AutoStartPort _autoStart;
  final PreferencesChangedPort _preferencesChanged;
  final DraftStore _draftStore;

  Future<PreferencesCommandResult> execute(RhythmSettingsDraft draft) async {
    final UserPreferences current = await _settingsRepository.load();
    final UserPreferences saved = current.applyRhythmSettings(
      configuration: draft.rhythmConfiguration,
      autoStartEnabled: draft.autoStartEnabled,
    );
    await _settingsRepository.save(saved);

    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      await _preferencesChanged.publish(
        PreferencesChangedEvent(
          preferences: saved,
          impact: PreferencesChangeImpact.rhythmSchedule,
        ),
      );
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.rhythmSchedule);
    }

    try {
      final AutoStartReconciliation reconciliation = await _autoStart.reconcile(
        desiredEnabled: saved.autoStartEnabled,
      );
      if (reconciliation.repairRequired) {
        repairNeeds.add(PreferencesRepairNeed.autoStart);
      }
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.autoStart);
    }

    try {
      await _draftStore.save(RhythmSettingsDraft.fromPreferences(saved));
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.draft);
    }
    return PreferencesCommandResult(
      preferences: saved,
      repairNeeds: repairNeeds,
    );
  }
}
