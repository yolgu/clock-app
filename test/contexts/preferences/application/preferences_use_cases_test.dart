import 'package:clock_rhythm/contexts/preferences/application/notification_sound_service.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/auto_start_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/draft_store.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/notification_sound_file_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/preferences_changed_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/settings_repository.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/sound_preview_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/preferences_command_result.dart';
import 'package:clock_rhythm/contexts/preferences/application/preferences_service.dart';
import 'package:clock_rhythm/contexts/preferences/application/rhythm_settings_service.dart';
import 'package:clock_rhythm/contexts/preferences/domain/language_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/notification_sound_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/rhythm_settings_draft.dart';
import 'package:clock_rhythm/contexts/preferences/domain/theme_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preferences service returns the persisted durable object', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final UserPreferences preferences = await harness.preferences.load();

    expect(preferences, UserPreferences.defaults());
  });

  test(
    'Save commits before reschedule and autostart, then resets draft',
    () async {
      final PreferencesHarness harness = PreferencesHarness();
      final RhythmSettingsDraft draft = RhythmSettingsDraft.fromPreferences(
        harness.repository.current,
      ).changeFocusMinutes(25).changeAutoStart(true);

      final PreferencesCommandResult result = await harness.rhythmSettings.save(
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

      final PreferencesCommandResult result = await harness.rhythmSettings.save(
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

    final PreferencesCommandResult result = await harness.preferences
        .changeLanguage(LanguagePreference.english);

    expect(result.preferences.language, LanguagePreference.english);
    expect(harness.calls, <String>[
      'repository.load',
      'repository.save',
      'changed.payload',
    ]);
  });

  test('theme applies durably before requesting the visual effect', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final PreferencesCommandResult result = await harness.preferences
        .changeTheme(ThemePreference.nord);

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
      await harness.rhythmSettings.storeDraft(changed);

      final RhythmSettingsDraft loaded = await harness.rhythmSettings
          .loadDraft();
      final RhythmSettingsDraft discarded = await harness.rhythmSettings
          .discardDraft();

      expect(loaded, changed);
      expect(
        discarded.isDirtyComparedWith(harness.repository.current),
        isFalse,
      );
    },
  );

  test('preview and stop delegate to the current sound owner', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final SoundPreviewPlayback playback = await harness.sound.preview();
    await playback.completed;
    await harness.sound.stopPreview();

    expect(harness.calls, <String>[
      'repository.load',
      'preview.play',
      'preview.stop',
    ]);
  });

  test('initial setup completion is one explicit durable command', () async {
    final PreferencesHarness harness = PreferencesHarness();

    final PreferencesCommandResult result = await harness.preferences
        .completeInitialSetup();

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

      final PreferencesCommandResult result = await harness.sound
          .chooseCustom();

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

    final PreferencesCommandResult result = await harness.sound.chooseCustom();

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
      final PreferencesHarness harness = PreferencesHarness(
        unmuteBehavior: UnmuteSoundBehavior.bundledDefault,
      );
      harness.repository.current = harness.repository.current
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'bell.mp3',
              privateSource: 'sound-v1/current.mp3',
            ),
          );
      final NotificationSoundService toggle = harness.sound;

      await toggle.toggleMute();
      final PreferencesCommandResult unmuted = await toggle.toggleMute();

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

    final PreferencesCommandResult result = await harness.sound.changeVolume(0);

    expect(result.preferences.notificationSound.volume, 0);
    expect(
      result.preferences.notificationSound.mode,
      NotificationSoundMode.bundledDefault,
    );
    expect(harness.calls.last, 'changed.sound');
  });
}

final class PreferencesHarness {
  PreferencesHarness({
    UnmuteSoundBehavior unmuteBehavior =
        UnmuteSoundBehavior.restorePreviousSelection,
  }) {
    repository = FakeSettingsRepository(calls);
    autoStart = FakeAutoStartPort(calls);
    changed = FakePreferencesChangedPort(calls);
    draftStore = FakeDraftStore(calls);
    soundFiles = FakeNotificationSoundFilePort(calls);
    preview = FakeSoundPreviewPort(calls);
    preferences = PreferencesService(
      settingsRepository: repository,
      preferencesChanged: changed,
    );
    rhythmSettings = RhythmSettingsService(
      settingsRepository: repository,
      autoStart: autoStart,
      preferencesChanged: changed,
      draftStore: draftStore,
    );
    sound = NotificationSoundService(
      settingsRepository: repository,
      soundFilePort: soundFiles,
      soundPreview: preview,
      preferencesChanged: changed,
      unmuteBehavior: unmuteBehavior,
    );
  }

  final List<String> calls = <String>[];
  late final FakeSettingsRepository repository;
  late final FakeAutoStartPort autoStart;
  late final FakePreferencesChangedPort changed;
  late final FakeDraftStore draftStore;
  late final FakeNotificationSoundFilePort soundFiles;
  late final FakeSoundPreviewPort preview;
  late final PreferencesService preferences;
  late final RhythmSettingsService rhythmSettings;
  late final NotificationSoundService sound;
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
