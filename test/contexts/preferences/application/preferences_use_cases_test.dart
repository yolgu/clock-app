import 'package:clock_rhythm/contexts/preferences/application/change_language.dart';
import 'package:clock_rhythm/contexts/preferences/application/change_notification_sound.dart';
import 'package:clock_rhythm/contexts/preferences/application/change_theme.dart';
import 'package:clock_rhythm/contexts/preferences/application/change_volume.dart';
import 'package:clock_rhythm/contexts/preferences/application/complete_initial_setup.dart';
import 'package:clock_rhythm/contexts/preferences/application/get_preferences.dart';
import 'package:clock_rhythm/contexts/preferences/application/load_rhythm_settings_draft.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/auto_start_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/draft_store.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/notification_sound_file_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/preferences_changed_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/settings_repository.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/sound_preview_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/preferences_command_result.dart';
import 'package:clock_rhythm/contexts/preferences/application/preview_notification_sound.dart';
import 'package:clock_rhythm/contexts/preferences/application/save_rhythm_settings.dart';
import 'package:clock_rhythm/contexts/preferences/application/store_rhythm_settings_draft.dart';
import 'package:clock_rhythm/contexts/preferences/application/toggle_mute.dart';
import 'package:clock_rhythm/contexts/preferences/domain/language_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/notification_sound_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/rhythm_settings_draft.dart';
import 'package:clock_rhythm/contexts/preferences/domain/theme_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GetPreferences returns the persisted durable object', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final UserPreferences preferences = await GetPreferences(
      harness.repository,
    ).execute();

    expect(preferences, UserPreferences.defaults());
  });

  test(
    'Save commits before reschedule and autostart, then resets draft',
    () async {
      final PreferencesHarness harness = PreferencesHarness();
      final RhythmSettingsDraft draft = RhythmSettingsDraft.fromPreferences(
        harness.repository.current,
      ).changeFocusMinutes(25).changeAutoStart(true);

      final PreferencesCommandResult result = await harness.saveRhythm.execute(
        draft,
      );

      expect(result.preferences.rhythmConfiguration.focusDuration.minutes, 25);
      expect(result.preferences.autoStartEnabled, isTrue);
      expect(result.preferences.initialSetupCompleted, isTrue);
      expect(result.repairNeeds, isEmpty);
      expect(harness.calls, <String>[
        'repository.load',
        'repository.save',
        'changed.rhythm',
        'autostart.reconcile:true',
        'draft.save',
      ]);
      expect(
        harness.draftStore.current?.isDirtyComparedWith(result.preferences),
        isFalse,
      );
    },
  );

  test(
    'side-effect failure keeps durable save and continues remaining reconciliation',
    () async {
      final PreferencesHarness harness = PreferencesHarness()
        ..changed.failRhythm = true
        ..autoStart.fail = true;
      final RhythmSettingsDraft draft = RhythmSettingsDraft.fromPreferences(
        harness.repository.current,
      ).changeRestMinutes(12).changeAutoStart(true);

      final PreferencesCommandResult result = await harness.saveRhythm.execute(
        draft,
      );

      expect(
        harness.repository.current.rhythmConfiguration.restDuration.minutes,
        12,
      );
      expect(result.repairNeeds, <PreferencesRepairNeed>{
        PreferencesRepairNeed.rhythmSchedule,
        PreferencesRepairNeed.autoStart,
      });
      expect(
        harness.calls,
        containsAllInOrder(<String>[
          'repository.save',
          'changed.rhythm',
          'autostart.reconcile:true',
          'draft.save',
        ]),
      );
    },
  );

  test('language applies durably before requesting payload refresh', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final PreferencesCommandResult result = await ChangeLanguage(
      settingsRepository: harness.repository,
      preferencesChanged: harness.changed,
    ).execute(LanguagePreference.english);

    expect(result.preferences.language, LanguagePreference.english);
    expect(harness.calls, <String>[
      'repository.load',
      'repository.save',
      'changed.payload',
    ]);
  });

  test('theme applies durably before requesting the visual effect', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final PreferencesCommandResult result = await ChangeTheme(
      settingsRepository: harness.repository,
      preferencesChanged: harness.changed,
    ).execute(ThemePreference.nord);

    expect(result.preferences.theme, ThemePreference.nord);
    expect(harness.calls, <String>[
      'repository.load',
      'repository.save',
      'changed.visual',
    ]);
  });

  test(
    'draft commands restore, store, and discard against durable truth',
    () async {
      final PreferencesHarness harness = PreferencesHarness();
      final RhythmSettingsDraft changed = RhythmSettingsDraft.fromPreferences(
        harness.repository.current,
      ).changeFocusMinutes(35);
      await StoreRhythmSettingsDraft(harness.draftStore).execute(changed);

      final RhythmSettingsDraft loaded = await LoadRhythmSettingsDraft(
        settingsRepository: harness.repository,
        draftStore: harness.draftStore,
      ).execute();
      final RhythmSettingsDraft discarded = await DiscardRhythmSettingsDraft(
        settingsRepository: harness.repository,
        draftStore: harness.draftStore,
      ).execute();

      expect(loaded, changed);
      expect(
        discarded.isDirtyComparedWith(harness.repository.current),
        isFalse,
      );
    },
  );

  test('preview and stop delegate to the current sound owner', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final SoundPreviewPlayback playback = await PreviewNotificationSound(
      settingsRepository: harness.repository,
      soundPreview: harness.preview,
    ).execute();
    await playback.completed;
    await StopNotificationSoundPreview(harness.preview).execute();

    expect(harness.calls, <String>[
      'repository.load',
      'preview.play',
      'preview.stop',
    ]);
  });

  test('initial setup completion is one explicit durable command', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final PreferencesCommandResult result = await CompleteInitialSetup(
      settingsRepository: harness.repository,
      preferencesChanged: harness.changed,
    ).execute();

    expect(result.preferences.initialSetupCompleted, isTrue);
    expect(harness.calls, <String>[
      'repository.load',
      'repository.save',
      'changed.visual',
    ]);
  });

  test(
    'sound selection cancellation stops preview and leaves durable state',
    () async {
      final PreferencesHarness harness = PreferencesHarness();
      harness.soundFiles.selected = null;

      final PreferencesCommandResult result = await ChangeNotificationSound(
        settingsRepository: harness.repository,
        soundFilePort: harness.soundFiles,
        soundPreview: harness.preview,
        preferencesChanged: harness.changed,
      ).chooseCustom();

      expect(result.preferences, UserPreferences.defaults());
      expect(harness.calls, <String>[
        'preview.stop',
        'soundFile.choose',
        'repository.load',
      ]);
    },
  );

  test('custom sound stops preview, saves, and refreshes payload', () async {
    final PreferencesHarness harness = PreferencesHarness();
    harness.soundFiles.selected = const SelectedNotificationSound(
      fileName: 'bell.mp3',
      privateSource: 'sound-v1/current.mp3',
    );

    final PreferencesCommandResult result = await ChangeNotificationSound(
      settingsRepository: harness.repository,
      soundFilePort: harness.soundFiles,
      soundPreview: harness.preview,
      preferencesChanged: harness.changed,
    ).chooseCustom();

    expect(
      result.preferences.notificationSound.mode,
      NotificationSoundMode.custom,
    );
    expect(harness.calls, <String>[
      'preview.stop',
      'soundFile.choose',
      'repository.load',
      'repository.save',
      'changed.payload',
    ]);
  });

  test(
    'Android mute round trip restores bundled sound and keeps notification visible',
    () async {
      final PreferencesHarness harness = PreferencesHarness();
      harness.repository.current = harness.repository.current
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'bell.mp3',
              privateSource: 'sound-v1/current.mp3',
            ),
          );
      final ToggleMute toggle = ToggleMute(
        settingsRepository: harness.repository,
        soundPreview: harness.preview,
        preferencesChanged: harness.changed,
        unmuteBehavior: UnmuteSoundBehavior.bundledDefault,
      );

      await toggle.execute();
      final PreferencesCommandResult unmuted = await toggle.execute();

      expect(
        unmuted.preferences.notificationSound.mode,
        NotificationSoundMode.bundledDefault,
      );
      expect(
        unmuted.preferences.notificationSound.isNotificationVisible,
        isTrue,
      );
    },
  );

  test('zero volume remains an immediate durable setting, not Mute', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final PreferencesCommandResult result = await ChangeVolume(
      settingsRepository: harness.repository,
      preferencesChanged: harness.changed,
    ).execute(0);

    expect(result.preferences.notificationSound.volume, 0);
    expect(
      result.preferences.notificationSound.mode,
      NotificationSoundMode.bundledDefault,
    );
    expect(harness.calls.last, 'changed.sound');
  });
}

final class PreferencesHarness {
  PreferencesHarness() {
    repository = FakeSettingsRepository(calls);
    autoStart = FakeAutoStartPort(calls);
    changed = FakePreferencesChangedPort(calls);
    draftStore = FakeDraftStore(calls);
    soundFiles = FakeNotificationSoundFilePort(calls);
    preview = FakeSoundPreviewPort(calls);
    saveRhythm = SaveRhythmSettings(
      settingsRepository: repository,
      autoStart: autoStart,
      preferencesChanged: changed,
      draftStore: draftStore,
    );
  }

  final List<String> calls = <String>[];
  late final FakeSettingsRepository repository;
  late final FakeAutoStartPort autoStart;
  late final FakePreferencesChangedPort changed;
  late final FakeDraftStore draftStore;
  late final FakeNotificationSoundFilePort soundFiles;
  late final FakeSoundPreviewPort preview;
  late final SaveRhythmSettings saveRhythm;
}

final class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository(this.calls);

  final List<String> calls;
  UserPreferences current = UserPreferences.defaults();

  @override
  Future<UserPreferences> load() async {
    calls.add('repository.load');
    return current;
  }

  @override
  Future<void> save(UserPreferences preferences) async {
    calls.add('repository.save');
    current = preferences;
  }
}

final class FakeAutoStartPort implements AutoStartPort {
  FakeAutoStartPort(this.calls);

  final List<String> calls;
  bool fail = false;

  @override
  Future<AutoStartReconciliation> reconcile({
    required bool desiredEnabled,
  }) async {
    calls.add('autostart.reconcile:$desiredEnabled');
    if (fail) {
      throw StateError('autostart unavailable');
    }
    return AutoStartReconciliation(
      desiredEnabled: desiredEnabled,
      actualEnabled: desiredEnabled,
    );
  }
}

final class FakePreferencesChangedPort implements PreferencesChangedPort {
  FakePreferencesChangedPort(this.calls);

  final List<String> calls;
  bool failRhythm = false;

  @override
  Future<void> publish(PreferencesChangedEvent event) async {
    calls.add('changed.${event.impact.logName}');
    if (failRhythm && event.impact == PreferencesChangeImpact.rhythmSchedule) {
      throw StateError('scheduler unavailable');
    }
  }
}

final class FakeDraftStore implements DraftStore {
  FakeDraftStore(this.calls);

  final List<String> calls;
  RhythmSettingsDraft? current;

  @override
  Future<void> clear() async {
    current = null;
    calls.add('draft.clear');
  }

  @override
  Future<RhythmSettingsDraft?> load() async => current;

  @override
  Future<void> save(RhythmSettingsDraft draft) async {
    current = draft;
    calls.add('draft.save');
  }
}

final class FakeNotificationSoundFilePort implements NotificationSoundFilePort {
  FakeNotificationSoundFilePort(this.calls);

  final List<String> calls;
  SelectedNotificationSound? selected;

  @override
  Future<SelectedNotificationSound?> chooseCustomMp3() async {
    calls.add('soundFile.choose');
    return selected;
  }
}

final class FakeSoundPreviewPort implements SoundPreviewPort {
  FakeSoundPreviewPort(this.calls);

  final List<String> calls;

  @override
  Future<SoundPreviewPlayback> play(NotificationSoundPreference sound) async {
    calls.add('preview.play');
    return SoundPreviewPlayback(completed: Future<void>.value());
  }

  @override
  Future<void> stop() async {
    calls.add('preview.stop');
  }
}
