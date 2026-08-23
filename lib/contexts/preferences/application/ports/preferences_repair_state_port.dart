import '../preferences_command_result.dart';

abstract interface class PreferencesRepairStatePort {
  Set<PreferencesRepairNeed> get current;

  Stream<Set<PreferencesRepairNeed>> watch();

  void report(PreferencesRepairNeed need);

  void recordCommandResult({
    required Set<PreferencesRepairNeed> attempted,
    required Set<PreferencesRepairNeed> reported,
  });
}
