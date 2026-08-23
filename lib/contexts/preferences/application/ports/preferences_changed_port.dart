import '../../domain/user_preferences.dart';

enum PreferencesChangeImpact {
  visual('visual'),
  sound('sound'),
  notificationPayload('payload'),
  rhythmSchedule('rhythm');

  const PreferencesChangeImpact(this.logName);

  final String logName;
}

final class PreferencesChangedEvent {
  const PreferencesChangedEvent({
    required this.preferences,
    required this.impact,
  });

  final UserPreferences preferences;
  final PreferencesChangeImpact impact;
}

abstract interface class PreferencesChangedPort {
  Future<void> publish(PreferencesChangedEvent event);
}
