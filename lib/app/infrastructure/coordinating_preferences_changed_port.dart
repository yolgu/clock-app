import '../../contexts/preferences/public.dart'
    show
        PreferencesChangeImpact,
        PreferencesChangedEvent,
        PreferencesChangedPort,
        UserPreferences;
import '../../contexts/rhythm/public.dart' show RescheduleRunningRhythm;

typedef PreferencesEffect = Future<void> Function(UserPreferences preferences);

final class CoordinatingPreferencesChangedPort
    implements PreferencesChangedPort {
  const CoordinatingPreferencesChangedPort({
    required this._rescheduleRhythm,
    required this._refreshDeliveryPayload,
    required this._refreshSound,
  });

  final RescheduleRunningRhythm _rescheduleRhythm;
  final PreferencesEffect _refreshDeliveryPayload;
  final PreferencesEffect _refreshSound;

  @override
  Future<void> publish(PreferencesChangedEvent event) {
    return switch (event.impact) {
      PreferencesChangeImpact.visual => Future<void>.value(),
      PreferencesChangeImpact.sound => _refreshSound(event.preferences),
      PreferencesChangeImpact.notificationPayload => _refreshDeliveryPayload(
        event.preferences,
      ),
      PreferencesChangeImpact.rhythmSchedule =>
        _rescheduleRhythm
            .execute(event.preferences.rhythmConfiguration)
            .then<void>((_) {}),
    };
  }
}
