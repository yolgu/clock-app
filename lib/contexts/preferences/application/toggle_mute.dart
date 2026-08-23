import '../domain/notification_sound_preference.dart';
import '../domain/user_preferences.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'ports/sound_preview_port.dart';
import 'preferences_command_result.dart';

final class ToggleMute {
  const ToggleMute({
    required this._settingsRepository,
    required this._soundPreview,
    required this._preferencesChanged,
    required this._unmuteBehavior,
  });

  final SettingsRepository _settingsRepository;
  final SoundPreviewPort _soundPreview;
  final PreferencesChangedPort _preferencesChanged;
  final UnmuteSoundBehavior _unmuteBehavior;

  Future<PreferencesCommandResult> execute() async {
    final UserPreferences saved = (await _settingsRepository.load()).toggleMute(
      _unmuteBehavior,
    );
    await _soundPreview.stop();
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
