import '../domain/user_preferences.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class CompleteInitialSetup {
  const CompleteInitialSetup({
    required this._settingsRepository,
    required this._preferencesChanged,
  });

  final SettingsRepository _settingsRepository;
  final PreferencesChangedPort _preferencesChanged;

  Future<PreferencesCommandResult> execute() async {
    final UserPreferences saved = (await _settingsRepository.load())
        .completeInitialSetup();
    await _settingsRepository.save(saved);
    await _preferencesChanged.publish(
      PreferencesChangedEvent(
        preferences: saved,
        impact: PreferencesChangeImpact.visual,
      ),
    );
    return PreferencesCommandResult(preferences: saved);
  }
}
