import 'package:clock_rhythm/contexts/preferences/domain/language_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/notification_sound_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/theme_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the agreed first-launch defaults', () {
    final UserPreferences preferences = UserPreferences.defaults();

    expect(preferences.rhythmConfiguration.focusDuration.minutes, 50);
    expect(preferences.rhythmConfiguration.restDuration.minutes, 10);
    expect(preferences.rhythmConfiguration.dailyRhythm.start.text, '05:00');
    expect(preferences.rhythmConfiguration.dailyRhythm.end.text, '18:00');
    expect(preferences.language, LanguagePreference.korean);
    expect(preferences.theme, ThemePreference.current);
    expect(
      preferences.notificationSound.mode,
      NotificationSoundMode.bundledDefault,
    );
    expect(preferences.notificationSound.volume, 1);
    expect(preferences.autoStartEnabled, isFalse);
    expect(preferences.initialSetupCompleted, isFalse);
  });

  test('publishes the exact stable backup theme identifiers in order', () {
    expect(
      ThemePreference.values.map((ThemePreference theme) => theme.id),
      <String>[
        'current',
        'tokyo-night',
        'one-dark-pro',
        'catppuccin-mocha',
        'nord',
        'dracula-official',
        'gruvbox',
        'monokai-pro',
        'night-owl',
        'synthwave-84',
        'ayu-mirage-dark',
      ],
    );
  });

  test('rejects present invalid language and theme identifiers', () {
    expect(() => LanguagePreference.parse('ko'), throwsFormatException);
    expect(() => ThemePreference.parse('unknown'), throwsFormatException);
  });

  test('mute keeps notifications enabled and preserves zero volume', () {
    final UserPreferences muted = UserPreferences.defaults()
        .changeVolume(0)
        .toggleMute(UnmuteSoundBehavior.restorePreviousSelection);

    expect(muted.notificationSound.mode, NotificationSoundMode.muted);
    expect(muted.notificationSound.volume, 0);
    expect(muted.notificationSound.isNotificationVisible, isTrue);
    expect(muted.notificationSound.isAudible, isFalse);
  });

  test('Windows unmute restores the previous custom selection and volume', () {
    final UserPreferences custom = UserPreferences.defaults()
        .changeNotificationSound(
          NotificationSoundPreference.custom(
            fileName: 'bell.mp3',
            privateSource: 'sound-v1/current.mp3',
            volume: 0.35,
          ),
        );

    final UserPreferences restored = custom
        .toggleMute(UnmuteSoundBehavior.restorePreviousSelection)
        .toggleMute(UnmuteSoundBehavior.restorePreviousSelection);

    expect(restored.notificationSound.mode, NotificationSoundMode.custom);
    expect(restored.notificationSound.customFileName, 'bell.mp3');
    expect(restored.notificationSound.privateSource, 'sound-v1/current.mp3');
    expect(restored.notificationSound.volume, 0.35);
  });

  test('Android unmute always returns to the bundled default', () {
    final UserPreferences custom = UserPreferences.defaults()
        .changeNotificationSound(
          NotificationSoundPreference.custom(
            fileName: 'bell.mp3',
            privateSource: 'sound-v1/current.mp3',
            volume: 0.4,
          ),
        );

    final UserPreferences restored = custom
        .toggleMute(UnmuteSoundBehavior.restorePreviousSelection)
        .toggleMute(UnmuteSoundBehavior.bundledDefault);

    expect(
      restored.notificationSound.mode,
      NotificationSoundMode.bundledDefault,
    );
    expect(restored.notificationSound.volume, 0.4);
  });

  test(
    'LB-073 completing first setup preserves every Rhythm Setting and round-trips the completion',
    () {
      final UserPreferences original = UserPreferences.defaults();

      final UserPreferences completed = original.completeInitialSetup();
      final UserPreferences restored = UserPreferences.restore(
        completed.snapshot(),
      );

      expect(completed.initialSetupCompleted, isTrue);
      expect(completed.rhythmConfiguration, original.rhythmConfiguration);
      expect(completed.autoStartEnabled, original.autoStartEnabled);
      expect(restored.initialSetupCompleted, isTrue);
      expect(restored.rhythmConfiguration, original.rhythmConfiguration);
      expect(restored.autoStartEnabled, original.autoStartEnabled);
    },
  );

  test(
    'LB-077 notification volume accepts its bounds and rejects overflow',
    () {
      expect(
        UserPreferences.defaults().changeVolume(0).notificationSound.volume,
        0,
      );
      expect(
        UserPreferences.defaults().changeVolume(1).notificationSound.volume,
        1,
      );
      expect(
        () => UserPreferences.defaults().changeVolume(-0.1),
        throwsArgumentError,
      );
      expect(
        () => UserPreferences.defaults().changeVolume(1.1),
        throwsArgumentError,
      );
    },
  );

  test('validates custom sound metadata and volume', () {
    expect(
      () => NotificationSoundPreference.custom(
        fileName: 'bell.wav',
        privateSource: 'sound-v1/current.mp3',
      ),
      throwsArgumentError,
    );
    expect(
      () => NotificationSoundPreference.bundledDefault(volume: double.nan),
      throwsArgumentError,
    );
    expect(
      () => NotificationSoundPreference.bundledDefault(volume: 1.01),
      throwsArgumentError,
    );
  });

  test('durable snapshot round-trips without any draft fields', () {
    final UserPreferences original = UserPreferences.defaults()
        .changeLanguage(LanguagePreference.english)
        .changeTheme(ThemePreference.nord)
        .changeAutoStart(true)
        .completeInitialSetup();

    final UserPreferencesSnapshot snapshot = original.snapshot();
    final UserPreferences restored = UserPreferences.restore(snapshot);

    expect(restored, original);
    expect(snapshot.toJsonLikeMap().keys, isNot(contains('draft')));
    expect(snapshot.toJsonLikeMap().keys, isNot(contains('isDirty')));
  });
}
