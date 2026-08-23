import 'ports/auto_start_port.dart';
import 'ports/settings_repository.dart';
import 'preferences_command_result.dart';

final class RepairAutoStart {
  const RepairAutoStart({
    required this._settingsRepository,
    required this._autoStart,
  });

  final SettingsRepository _settingsRepository;
  final AutoStartPort _autoStart;

  Future<PreferencesCommandResult> execute() async {
    final preferences = await _settingsRepository.load();
    final Set<PreferencesRepairNeed> repairNeeds = <PreferencesRepairNeed>{};
    try {
      final AutoStartReconciliation reconciliation = await _autoStart.reconcile(
        desiredEnabled: preferences.autoStartEnabled,
      );
      if (reconciliation.repairRequired) {
        repairNeeds.add(PreferencesRepairNeed.autoStart);
      }
    } on Object {
      repairNeeds.add(PreferencesRepairNeed.autoStart);
    }
    return PreferencesCommandResult(
      preferences: preferences,
      repairNeeds: repairNeeds,
    );
  }
}
