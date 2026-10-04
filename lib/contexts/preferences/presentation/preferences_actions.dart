import '../application/notification_sound_service.dart';
import '../application/ports/preferences_changed_port.dart';
import '../application/ports/preferences_repair_state_port.dart';
import '../application/ports/sound_preview_port.dart';
import '../application/preferences_command_result.dart';
import '../application/preferences_service.dart';
import '../application/rhythm_settings_service.dart';
import '../domain/language_preference.dart';
import '../domain/rhythm_settings_draft.dart';
import '../domain/theme_preference.dart';
import '../domain/user_preferences.dart';

final class PreferencesInitialData {
  PreferencesInitialData({
    required this.preferences,
    required this.draft,
    Set<PreferencesRepairNeed> repairNeeds = const <PreferencesRepairNeed>{},
  }) : repairNeeds = Set<PreferencesRepairNeed>.unmodifiable(repairNeeds);

  final UserPreferences preferences;
  final RhythmSettingsDraft draft;
  final Set<PreferencesRepairNeed> repairNeeds;
}

abstract interface class PreferencesActions {
  Future<PreferencesInitialData> load();

  Stream<Set<PreferencesRepairNeed>> watchRepairNeeds();

  Future<void> storeDraft(RhythmSettingsDraft draft);

  Future<RhythmSettingsDraft> discardDraft();

  Future<PreferencesCommandResult> saveRhythm(RhythmSettingsDraft draft);

  Future<PreferencesCommandResult> changeLanguage(LanguagePreference language);

  Future<PreferencesCommandResult> changeTheme(ThemePreference theme);

  Future<PreferencesCommandResult> useBundledSound();

  Future<PreferencesCommandResult> chooseCustomSound();

  Future<PreferencesCommandResult> changeVolume(double volume);

  Future<PreferencesCommandResult> toggleMute();

  Future<SoundPreviewPlayback> previewSound();

  Future<void> stopSoundPreview();

  Future<PreferencesCommandResult> repairEffect(PreferencesChangeImpact impact);

  Future<PreferencesCommandResult> repairAutoStart();
}

final class ApplicationPreferencesActions implements PreferencesActions {
  const ApplicationPreferencesActions({
    required this._preferences,
    required this._rhythmSettings,
    required this._sound,
    required this._repairState,
  });

  final PreferencesService _preferences;
  final RhythmSettingsService _rhythmSettings;
  final NotificationSoundService _sound;
  final PreferencesRepairStatePort _repairState;

  @override
  Future<PreferencesInitialData> load() async {
    final UserPreferences preferences = await _preferences.load();
    final RhythmSettingsDraft draft = await _rhythmSettings.loadDraft();
    return PreferencesInitialData(
      preferences: preferences,
      draft: draft,
      repairNeeds: _repairState.current,
    );
  }

  @override
  Stream<Set<PreferencesRepairNeed>> watchRepairNeeds() {
    return _repairState.watch();
  }

  @override
  Future<void> storeDraft(RhythmSettingsDraft draft) async {
    await _rhythmSettings.storeDraft(draft);
    _repairState.recordCommandResult(
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.draft},
      reported: const <PreferencesRepairNeed>{},
    );
  }

  @override
  Future<RhythmSettingsDraft> discardDraft() async {
    final RhythmSettingsDraft discarded = await _rhythmSettings.discardDraft();
    _repairState.recordCommandResult(
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.draft},
      reported: const <PreferencesRepairNeed>{},
    );
    return discarded;
  }

  @override
  Future<PreferencesCommandResult> saveRhythm(RhythmSettingsDraft draft) {
    return _runCommand(
      () => _rhythmSettings.save(draft),
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.rhythmSchedule,
        PreferencesRepairNeed.autoStart,
        PreferencesRepairNeed.draft,
      },
    );
  }

  @override
  Future<PreferencesCommandResult> changeLanguage(LanguagePreference language) {
    return _runCommand(
      () => _preferences.changeLanguage(language),
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<PreferencesCommandResult> changeTheme(ThemePreference theme) {
    return _runCommand(
      () => _preferences.changeTheme(theme),
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.visual},
    );
  }

  @override
  Future<PreferencesCommandResult> useBundledSound() {
    return _runCommand(
      _sound.useBundledDefault,
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<PreferencesCommandResult> chooseCustomSound() {
    return _runCommand(
      _sound.chooseCustom,
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<PreferencesCommandResult> changeVolume(double volume) {
    return _runCommand(
      () => _sound.changeVolume(volume),
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
    );
  }

  @override
  Future<PreferencesCommandResult> toggleMute() {
    return _runCommand(
      _sound.toggleMute,
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<SoundPreviewPlayback> previewSound() {
    return _sound.preview();
  }

  @override
  Future<void> stopSoundPreview() {
    return _sound.stopPreview();
  }

  @override
  Future<PreferencesCommandResult> repairEffect(
    PreferencesChangeImpact impact,
  ) {
    final PreferencesRepairNeed repairNeed = switch (impact) {
      PreferencesChangeImpact.visual => PreferencesRepairNeed.visual,
      PreferencesChangeImpact.sound => PreferencesRepairNeed.sound,
      PreferencesChangeImpact.notificationPayload =>
        PreferencesRepairNeed.notificationPayload,
      PreferencesChangeImpact.rhythmSchedule =>
        PreferencesRepairNeed.rhythmSchedule,
    };
    return _runCommand(
      () => _preferences.repairEffect(impact),
      attempted: <PreferencesRepairNeed>{repairNeed},
    );
  }

  @override
  Future<PreferencesCommandResult> repairAutoStart() {
    return _runCommand(
      _rhythmSettings.repairAutoStart,
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.autoStart},
    );
  }

  Future<PreferencesCommandResult> _runCommand(
    Future<PreferencesCommandResult> Function() command, {
    required Set<PreferencesRepairNeed> attempted,
  }) async {
    final PreferencesCommandResult result = await command();
    _repairState.recordCommandResult(
      attempted: attempted,
      reported: result.repairNeeds,
    );
    return PreferencesCommandResult(
      preferences: result.preferences,
      repairNeeds: _repairState.current,
    );
  }
}
