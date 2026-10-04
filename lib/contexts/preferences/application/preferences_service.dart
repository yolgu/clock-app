import '../domain/language_preference.dart';
import '../domain/theme_preference.dart';
import '../domain/user_preferences.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class PreferencesService {
  const PreferencesService({
    required this._settingsRepository,
    required this._preferencesChanged,
  });
  final SettingsRepository _settingsRepository;
  final PreferencesChangedPort _preferencesChanged;
  Future<UserPreferences> load() => _settingsRepository.load();

  Future<PreferencesCommandResult> changeLanguage(
    LanguagePreference language,
  ) async {
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

  Future<PreferencesCommandResult> changeTheme(ThemePreference theme) async {
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

  Future<PreferencesCommandResult> completeInitialSetup() async {
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

  Future<PreferencesCommandResult> repairEffect(
    PreferencesChangeImpact impact,
  ) async {
    final UserPreferences preferences = await _settingsRepository.load();
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
