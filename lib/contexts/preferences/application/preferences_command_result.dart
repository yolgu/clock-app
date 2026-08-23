import '../domain/user_preferences.dart';

enum PreferencesRepairNeed {
  rhythmSchedule,
  autoStart,
  notificationPayload,
  visual,
  sound,
  draft,
}

final class PreferencesCommandResult {
  PreferencesCommandResult({
    required this.preferences,
    Set<PreferencesRepairNeed> repairNeeds = const <PreferencesRepairNeed>{},
  }) : repairNeeds = Set<PreferencesRepairNeed>.unmodifiable(repairNeeds);

  final UserPreferences preferences;
  final Set<PreferencesRepairNeed> repairNeeds;
}
