import '../../rhythm/public_model.dart';
import 'user_preferences.dart';

final class RhythmSettingsDraftSnapshot {
  const RhythmSettingsDraftSnapshot({
    required this.focusMinutes,
    required this.restMinutes,
    required this.dailyStart,
    required this.dailyEnd,
    required this.autoStartEnabled,
  });

  final int focusMinutes;
  final int restMinutes;
  final String dailyStart;
  final String dailyEnd;
  final bool autoStartEnabled;
}

final class RhythmSettingsDraft {
  const RhythmSettingsDraft._({
    required this.rhythmConfiguration,
    required this.autoStartEnabled,
  });

  final RhythmConfiguration rhythmConfiguration;
  final bool autoStartEnabled;

  factory RhythmSettingsDraft.fromPreferences(UserPreferences preferences) {
    return RhythmSettingsDraft._(
      rhythmConfiguration: preferences.rhythmConfiguration,
      autoStartEnabled: preferences.autoStartEnabled,
    );
  }

  factory RhythmSettingsDraft.restore(RhythmSettingsDraftSnapshot snapshot) {
    return RhythmSettingsDraft._(
      rhythmConfiguration: RhythmConfiguration(
        dailyRhythm: DailyRhythm(
          start: ClockTime.parse(snapshot.dailyStart),
          end: ClockTime.parse(snapshot.dailyEnd),
        ),
        focusDuration: DurationMinutes.focus(snapshot.focusMinutes),
        restDuration: DurationMinutes.rest(snapshot.restMinutes),
      ),
      autoStartEnabled: snapshot.autoStartEnabled,
    );
  }

  RhythmSettingsDraft changeFocusMinutes(int minutes) {
    return _withConfiguration(
      RhythmConfiguration(
        dailyRhythm: rhythmConfiguration.dailyRhythm,
        focusDuration: DurationMinutes.focus(minutes),
        restDuration: rhythmConfiguration.restDuration,
      ),
    );
  }

  RhythmSettingsDraft changeRestMinutes(int minutes) {
    return _withConfiguration(
      RhythmConfiguration(
        dailyRhythm: rhythmConfiguration.dailyRhythm,
        focusDuration: rhythmConfiguration.focusDuration,
        restDuration: DurationMinutes.rest(minutes),
      ),
    );
  }

  RhythmSettingsDraft changeDailyRhythm({
    required String start,
    required String end,
  }) {
    return _withConfiguration(
      RhythmConfiguration(
        dailyRhythm: DailyRhythm(
          start: ClockTime.parse(start),
          end: ClockTime.parse(end),
        ),
        focusDuration: rhythmConfiguration.focusDuration,
        restDuration: rhythmConfiguration.restDuration,
      ),
    );
  }

  RhythmSettingsDraft changeAutoStart(bool enabled) {
    return RhythmSettingsDraft._(
      rhythmConfiguration: rhythmConfiguration,
      autoStartEnabled: enabled,
    );
  }

  bool isDirtyComparedWith(UserPreferences preferences) {
    return rhythmConfiguration != preferences.rhythmConfiguration ||
        autoStartEnabled != preferences.autoStartEnabled;
  }

  RhythmSettingsDraftSnapshot snapshot() {
    return RhythmSettingsDraftSnapshot(
      focusMinutes: rhythmConfiguration.focusDuration.minutes,
      restMinutes: rhythmConfiguration.restDuration.minutes,
      dailyStart: rhythmConfiguration.dailyRhythm.start.text,
      dailyEnd: rhythmConfiguration.dailyRhythm.end.text,
      autoStartEnabled: autoStartEnabled,
    );
  }

  RhythmSettingsDraft _withConfiguration(RhythmConfiguration configuration) {
    return RhythmSettingsDraft._(
      rhythmConfiguration: configuration,
      autoStartEnabled: autoStartEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RhythmSettingsDraft &&
            rhythmConfiguration == other.rhythmConfiguration &&
            autoStartEnabled == other.autoStartEnabled;
  }

  @override
  int get hashCode => Object.hash(rhythmConfiguration, autoStartEnabled);
}
