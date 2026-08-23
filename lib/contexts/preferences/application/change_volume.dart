import '../domain/user_preferences.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class ChangeVolume {
  const ChangeVolume({
    required this._settingsRepository,
    required this._preferencesChanged,
  });

  final SettingsRepository _settingsRepository;
  final PreferencesChangedPort _preferencesChanged;

  Future<PreferencesCommandResult> execute(double volume) async {
    final UserPreferences saved = (await _settingsRepository.load())
        .changeVolume(volume);
    await _settingsRepository.save(saved);
    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      await _preferencesChanged.publish(
        PreferencesChangedEvent(
          preferences: saved,
          impact: PreferencesChangeImpact.sound,
        ),
      );
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.sound);
    }
    return PreferencesCommandResult(
      preferences: saved,
      repairNeeds: repairNeeds,
    );
  }
}
