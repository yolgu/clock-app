import '../domain/notification_sound_preference.dart';
import '../domain/user_preferences.dart';
import 'ports/notification_sound_file_port.dart';
import 'ports/preferences_changed_port.dart';
import 'ports/settings_repository.dart';
import 'ports/sound_preview_port.dart';
import 'preferences_command_result.dart';

final class NotificationSoundService {
  const NotificationSoundService({
    required this._settingsRepository,
    required this._soundFilePort,
    required this._soundPreview,
    required this._preferencesChanged,
    required this._unmuteBehavior,
  });
  final SettingsRepository _settingsRepository;
  final NotificationSoundFilePort _soundFilePort;
  final SoundPreviewPort _soundPreview;
  final PreferencesChangedPort _preferencesChanged;
  final UnmuteSoundBehavior _unmuteBehavior;

  Future<PreferencesCommandResult> useBundledDefault() async {
    final UserPreferences current = await _settingsRepository.load();
    return _save(
      current.changeNotificationSound(
        current.notificationSound.useBundledDefault(),
      ),
    );
  }

  Future<PreferencesCommandResult> chooseCustom() async {
    await _soundPreview.stop();
    final SelectedNotificationSound? selected = await _soundFilePort
        .chooseCustomMp3();
    final UserPreferences current = await _settingsRepository.load();
    if (selected == null) {
      return PreferencesCommandResult(preferences: current);
    }
    final TransactionalNotificationSoundFilePort? transactionalSoundFiles =
        _soundFilePort is TransactionalNotificationSoundFilePort
        ? _soundFilePort
        : null;
    try {
      final PreferencesCommandResult saved = await _save(
        current.changeNotificationSound(
          NotificationSoundPreference.custom(
            fileName: selected.fileName,
            privateSource: selected.privateSource,
            volume: current.notificationSound.volume,
          ),
        ),
        stopPreview: false,
      );
      if (transactionalSoundFiles == null) {
        return saved;
      }
      try {
        final NotificationSoundAdoptionResult adoption =
            await transactionalSoundFiles.confirmAdoption(selected);
        if (!adoption.cleanupRequired) {
          return saved;
        }
      } on Object {
        // The durable preference already points at the validated new file.
        // A later repair may safely retry cleanup of unreferenced old media.
      }
      return PreferencesCommandResult(
        preferences: saved.preferences,
        repairNeeds: <PreferencesRepairNeed>{
          ...saved.repairNeeds,
          PreferencesRepairNeed.sound,
        },
      );
    } on Object {
      if (transactionalSoundFiles != null) {
        try {
          await transactionalSoundFiles.discardAdoption(selected);
        } on Object {
          // Preserve the durable save failure. An unreferenced candidate is
          // safer than deleting the previously selected private sound.
        }
      }
      rethrow;
    }
  }

  Future<PreferencesCommandResult> _save(
    UserPreferences preferences, {
    bool stopPreview = true,
  }) async {
    if (stopPreview) {
      await _soundPreview.stop();
    }
    await _settingsRepository.save(preferences);
    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      await _preferencesChanged.publish(
        PreferencesChangedEvent(
          preferences: preferences,
          impact: PreferencesChangeImpact.notificationPayload,
        ),
      );
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.notificationPayload);
    }
    return PreferencesCommandResult(
      preferences: preferences,
      repairNeeds: repairNeeds,
    );
  }

  Future<PreferencesCommandResult> changeVolume(double volume) async {
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

  Future<PreferencesCommandResult> toggleMute() async {
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

  Future<SoundPreviewPlayback> preview() async {
    final UserPreferences preferences = await _settingsRepository.load();
    return _soundPreview.play(preferences.notificationSound);
  }

  Future<void> stopPreview() {
    return _soundPreview.stop();
  }
}
