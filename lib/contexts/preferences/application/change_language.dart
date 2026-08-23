import '../domain/language_preference.dart';
import '../domain/user_preferences.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class ChangeLanguage {
  const ChangeLanguage({
    required this._settingsRepository,
    required this._preferencesChanged,
  });

  final SettingsRepository _settingsRepository;
  final PreferencesChangedPort _preferencesChanged;

  Future<PreferencesCommandResult> execute(LanguagePreference language) async {
    final UserPreferences saved = (await _settingsRepository.load())
        .changeLanguage(language);
    await _settingsRepository.save(saved);
    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      await _preferencesChanged.publish(
        PreferencesChangedEvent(
          preferences: saved,
          impact: PreferencesChangeImpact.notificationPayload,
        ),
      );
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.notificationPayload);
    }
    return PreferencesCommandResult(
      preferences: saved,
      repairNeeds: repairNeeds,
    );
  }
}
