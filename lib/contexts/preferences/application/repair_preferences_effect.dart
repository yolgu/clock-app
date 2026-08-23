import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class RepairPreferencesEffect {
  const RepairPreferencesEffect({
    required this._settingsRepository,
    required this._preferencesChanged,
  });

  final SettingsRepository _settingsRepository;
  final PreferencesChangedPort _preferencesChanged;

  Future<PreferencesCommandResult> execute(
    PreferencesChangeImpact impact,
  ) async {
    final preferences = await _settingsRepository.load();
    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      await _preferencesChanged.publish(
        PreferencesChangedEvent(preferences: preferences, impact: impact),
      );
    } on Object {
      repairNeeds.add(_repairNeed(impact));
    }
    return PreferencesCommandResult(
      preferences: preferences,
      repairNeeds: repairNeeds,
    );
  }

  PreferencesRepairNeed _repairNeed(PreferencesChangeImpact impact) {
    return switch (impact) {
      PreferencesChangeImpact.visual => PreferencesRepairNeed.visual,
      PreferencesChangeImpact.sound => PreferencesRepairNeed.sound,
      PreferencesChangeImpact.notificationPayload =>
        PreferencesRepairNeed.notificationPayload,
      PreferencesChangeImpact.rhythmSchedule =>
        PreferencesRepairNeed.rhythmSchedule,
    };
  }
}
