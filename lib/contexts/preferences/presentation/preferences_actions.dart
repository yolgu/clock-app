import '../application/change_language.dart';
import '../application/change_notification_sound.dart';
import '../application/change_theme.dart';
import '../application/change_volume.dart';
import '../application/get_preferences.dart';
import '../application/load_rhythm_settings_draft.dart';
import '../application/ports/preferences_changed_port.dart';
import '../application/ports/preferences_repair_state_port.dart';
import '../application/ports/sound_preview_port.dart';
import '../application/preferences_command_result.dart';
import '../application/preview_notification_sound.dart';
import '../application/repair_auto_start.dart';
import '../application/repair_preferences_effect.dart';
import '../application/save_rhythm_settings.dart';
import '../application/store_rhythm_settings_draft.dart';
import '../application/toggle_mute.dart';
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
  factory ApplicationPreferencesActions({
    required GetPreferences getPreferences,
    required LoadRhythmSettingsDraft loadDraft,
    required StoreRhythmSettingsDraft storeDraft,
    required DiscardRhythmSettingsDraft discardDraft,
    required SaveRhythmSettings saveRhythm,
    required ChangeLanguage changeLanguage,
    required ChangeTheme changeTheme,
    required ChangeNotificationSound changeSound,
    required ChangeVolume changeVolume,
    required ToggleMute toggleMute,
    required PreviewNotificationSound previewSound,
    required StopNotificationSoundPreview stopSoundPreview,
    required RepairPreferencesEffect repairEffect,
    required RepairAutoStart repairAutoStart,
    required PreferencesRepairStatePort repairState,
  }) {
    return ApplicationPreferencesActions._(
      getPreferences,
      loadDraft,
      storeDraft,
      discardDraft,
      saveRhythm,
      changeLanguage,
      changeTheme,
      changeSound,
      changeVolume,
      toggleMute,
      previewSound,
      stopSoundPreview,
      repairEffect,
      repairAutoStart,
      repairState,
    );
  }

  const ApplicationPreferencesActions._(
    this._getPreferences,
    this._loadDraft,
    this._storeDraft,
    this._discardDraft,
    this._saveRhythm,
    this._changeLanguage,
    this._changeTheme,
    this._changeSound,
    this._changeVolume,
    this._toggleMute,
    this._previewSound,
    this._stopSoundPreview,
    this._repairEffect,
    this._repairAutoStart,
    this._repairState,
  );

  final GetPreferences _getPreferences;
  final LoadRhythmSettingsDraft _loadDraft;
  final StoreRhythmSettingsDraft _storeDraft;
  final DiscardRhythmSettingsDraft _discardDraft;
  final SaveRhythmSettings _saveRhythm;
  final ChangeLanguage _changeLanguage;
  final ChangeTheme _changeTheme;
  final ChangeNotificationSound _changeSound;
  final ChangeVolume _changeVolume;
  final ToggleMute _toggleMute;
  final PreviewNotificationSound _previewSound;
  final StopNotificationSoundPreview _stopSoundPreview;
  final RepairPreferencesEffect _repairEffect;
  final RepairAutoStart _repairAutoStart;
  final PreferencesRepairStatePort _repairState;

  @override
  Future<PreferencesInitialData> load() async {
    final UserPreferences preferences = await _getPreferences.execute();
    final RhythmSettingsDraft draft = await _loadDraft.execute();
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
    await _storeDraft.execute(draft);
    _repairState.recordCommandResult(
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.draft},
      reported: const <PreferencesRepairNeed>{},
    );
  }

  @override
  Future<RhythmSettingsDraft> discardDraft() async {
    final RhythmSettingsDraft discarded = await _discardDraft.execute();
    _repairState.recordCommandResult(
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.draft},
      reported: const <PreferencesRepairNeed>{},
    );
    return discarded;
  }

  @override
  Future<PreferencesCommandResult> saveRhythm(RhythmSettingsDraft draft) {
    return _runCommand(
      () => _saveRhythm.execute(draft),
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
      () => _changeLanguage.execute(language),
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<PreferencesCommandResult> changeTheme(ThemePreference theme) {
    return _runCommand(
      () => _changeTheme.execute(theme),
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.visual},
    );
  }

  @override
  Future<PreferencesCommandResult> useBundledSound() {
    return _runCommand(
      _changeSound.useBundledDefault,
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<PreferencesCommandResult> chooseCustomSound() {
    return _runCommand(
      _changeSound.chooseCustom,
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<PreferencesCommandResult> changeVolume(double volume) {
    return _runCommand(
      () => _changeVolume.execute(volume),
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
    );
  }

  @override
  Future<PreferencesCommandResult> toggleMute() {
    return _runCommand(
      _toggleMute.execute,
      attempted: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  @override
  Future<SoundPreviewPlayback> previewSound() {
    return _previewSound.execute();
  }

  @override
  Future<void> stopSoundPreview() {
    return _stopSoundPreview.execute();
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
      () => _repairEffect.execute(impact),
      attempted: <PreferencesRepairNeed>{repairNeed},
    );
  }

  @override
  Future<PreferencesCommandResult> repairAutoStart() {
    return _runCommand(
      _repairAutoStart.execute,
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
