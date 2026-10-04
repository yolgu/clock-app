import '../domain/rhythm_settings_draft.dart';
import '../domain/user_preferences.dart';
import 'ports/auto_start_port.dart';
import 'ports/draft_store.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class RhythmSettingsService {
  const RhythmSettingsService({
    required this._settingsRepository,
    required this._draftStore,
    required this._autoStart,
    required this._preferencesChanged,
  });
  final SettingsRepository _settingsRepository;
  final DraftStore _draftStore;
  final AutoStartPort _autoStart;
  final PreferencesChangedPort _preferencesChanged;

  Future<RhythmSettingsDraft> loadDraft() async {
    final RhythmSettingsDraft? stored = await _draftStore.load();
    if (stored != null) {
      return stored;
    }
    final UserPreferences durable = await _settingsRepository.load();
    return RhythmSettingsDraft.fromPreferences(durable);
  }

  Future<void> storeDraft(RhythmSettingsDraft draft) {
    return _draftStore.save(draft);
  }

  Future<RhythmSettingsDraft> discardDraft() async {
    final UserPreferences durable = await _settingsRepository.load();
    final RhythmSettingsDraft clean = RhythmSettingsDraft.fromPreferences(
      durable,
    );
    await _draftStore.save(clean);
    return clean;
  }

  Future<PreferencesCommandResult> save(RhythmSettingsDraft draft) async {
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

  Future<PreferencesCommandResult> repairAutoStart() async {
    final UserPreferences preferences = await _settingsRepository.load();
    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      final AutoStartReconciliation reconciliation = await _autoStart.reconcile(
        desiredEnabled: preferences.autoStartEnabled,
      );
      if (reconciliation.repairRequired) {
        repairNeeds.add(PreferencesRepairNeed.autoStart);
      }
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.autoStart);
    }
    return PreferencesCommandResult(
      preferences: preferences,
      repairNeeds: repairNeeds,
    );
  }
}
