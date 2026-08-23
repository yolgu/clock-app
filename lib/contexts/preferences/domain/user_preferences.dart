import '../../rhythm/public_model.dart';
import 'language_preference.dart';
import 'notification_sound_preference.dart';
import 'theme_preference.dart';

final class UserPreferencesSnapshot {
  const UserPreferencesSnapshot({
    required this.focusMinutes,
    required this.restMinutes,
    required this.dailyStart,
    required this.dailyEnd,
    required this.autoStartEnabled,
    required this.notificationSound,
    required this.language,
    required this.theme,
    required this.initialSetupCompleted,
  });

  final int focusMinutes;
  final int restMinutes;
  final String dailyStart;
  final String dailyEnd;
  final bool autoStartEnabled;
  final NotificationSoundSnapshot notificationSound;
  final LanguagePreference language;
  final ThemePreference theme;
  final bool initialSetupCompleted;

  Map<String, Object?> toJsonLikeMap() {
    return <String, Object?>{
      'focusMinutes': focusMinutes,
      'restMinutes': restMinutes,
      'dailyStart': dailyStart,
      'dailyEnd': dailyEnd,
      'autoStartEnabled': autoStartEnabled,
      'notificationSound': notificationSound.toJsonLikeMap(),
      'language': language.id,
      'theme': theme.id,
      'initialSetupCompleted': initialSetupCompleted,
    };
  }
}

final class UserPreferences {
  const UserPreferences._({
    required this.rhythmConfiguration,
    required this.autoStartEnabled,
    required this.notificationSound,
    required this.language,
    required this.theme,
    required this.initialSetupCompleted,
  });

  final RhythmConfiguration rhythmConfiguration;
  final bool autoStartEnabled;
  final NotificationSoundPreference notificationSound;
  final LanguagePreference language;
  final ThemePreference theme;
  final bool initialSetupCompleted;

  factory UserPreferences.defaults() {
    return UserPreferences._(
      rhythmConfiguration: RhythmConfiguration.defaults(),
      autoStartEnabled: false,
      notificationSound: NotificationSoundPreference.bundledDefault(),
      language: LanguagePreference.korean,
      theme: ThemePreference.current,
      initialSetupCompleted: false,
    );
  }

  factory UserPreferences.restore(UserPreferencesSnapshot snapshot) {
    return UserPreferences._(
      rhythmConfiguration: RhythmConfiguration(
        dailyRhythm: DailyRhythm(
          start: ClockTime.parse(snapshot.dailyStart),
          end: ClockTime.parse(snapshot.dailyEnd),
        ),
        focusDuration: DurationMinutes.focus(snapshot.focusMinutes),
        restDuration: DurationMinutes.rest(snapshot.restMinutes),
      ),
      autoStartEnabled: snapshot.autoStartEnabled,
      notificationSound: NotificationSoundPreference.restore(
        snapshot.notificationSound,
      ),
      language: snapshot.language,
      theme: snapshot.theme,
      initialSetupCompleted: snapshot.initialSetupCompleted,
    );
  }

  UserPreferences applyRhythmSettings({
    required RhythmConfiguration configuration,
    required bool autoStartEnabled,
  }) {
    return _copyWith(
      rhythmConfiguration: configuration,
      autoStartEnabled: autoStartEnabled,
      initialSetupCompleted: true,
    );
  }

  UserPreferences changeAutoStart(bool enabled) {
    return _copyWith(autoStartEnabled: enabled);
  }

  UserPreferences changeLanguage(LanguagePreference nextLanguage) {
    return _copyWith(language: nextLanguage);
  }

  UserPreferences changeTheme(ThemePreference nextTheme) {
    return _copyWith(theme: nextTheme);
  }

  UserPreferences changeNotificationSound(
    NotificationSoundPreference nextSound,
  ) {
    return _copyWith(notificationSound: nextSound);
  }

  UserPreferences changeVolume(double volume) {
    return _copyWith(notificationSound: notificationSound.changeVolume(volume));
  }

  UserPreferences toggleMute(UnmuteSoundBehavior behavior) {
    return _copyWith(notificationSound: notificationSound.toggleMute(behavior));
  }

  UserPreferences completeInitialSetup() {
    return _copyWith(initialSetupCompleted: true);
  }

  UserPreferencesSnapshot snapshot() {
    return UserPreferencesSnapshot(
      focusMinutes: rhythmConfiguration.focusDuration.minutes,
      restMinutes: rhythmConfiguration.restDuration.minutes,
      dailyStart: rhythmConfiguration.dailyRhythm.start.text,
      dailyEnd: rhythmConfiguration.dailyRhythm.end.text,
      autoStartEnabled: autoStartEnabled,
      notificationSound: notificationSound.snapshot(),
      language: language,
      theme: theme,
      initialSetupCompleted: initialSetupCompleted,
    );
  }

  UserPreferences _copyWith({
    RhythmConfiguration? rhythmConfiguration,
    bool? autoStartEnabled,
    NotificationSoundPreference? notificationSound,
    LanguagePreference? language,
    ThemePreference? theme,
    bool? initialSetupCompleted,
  }) {
    return UserPreferences._(
      rhythmConfiguration: rhythmConfiguration ?? this.rhythmConfiguration,
      autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      initialSetupCompleted:
          initialSetupCompleted ?? this.initialSetupCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserPreferences &&
            rhythmConfiguration == other.rhythmConfiguration &&
            autoStartEnabled == other.autoStartEnabled &&
            notificationSound == other.notificationSound &&
            language == other.language &&
            theme == other.theme &&
            initialSetupCompleted == other.initialSetupCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      rhythmConfiguration,
      autoStartEnabled,
      notificationSound,
      language,
      theme,
      initialSetupCompleted,
    );
  }
}
