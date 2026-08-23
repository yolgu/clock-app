import '../domain/theme_preference.dart';
import '../domain/user_preferences.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class ChangeTheme {
  const ChangeTheme({
    required this._settingsRepository,
    required this._preferencesChanged,
  });

  final SettingsRepository _settingsRepository;
  final PreferencesChangedPort _preferencesChanged;

  Future<PreferencesCommandResult> execute(ThemePreference theme) async {
    final UserPreferences saved = (await _settingsRepository.load())
        .changeTheme(theme);
    await _settingsRepository.save(saved);
    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      await _preferencesChanged.publish(
        PreferencesChangedEvent(
          preferences: saved,
          impact: PreferencesChangeImpact.visual,
        ),
      );
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.visual);
    }
    return PreferencesCommandResult(
      preferences: saved,
      repairNeeds: repairNeeds,
    );
  }
}
