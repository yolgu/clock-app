import '../application/backup_failure.dart';
import '../application/prepare_backup_import.dart';

enum DataTransferPhase { idle, exporting, preparing, prepared, confirming }

enum DataTransferSuccess { none, exported, imported }

final class DataTransferState {
  const DataTransferState({
    this.phase = DataTransferPhase.idle,
    this.prepared,
    this.failure,
    this.success = DataTransferSuccess.none,
    this.autoStartRepairRequired = false,
    this.refreshRequired = false,
  });

  final DataTransferPhase phase;
  final PreparedBackupImport? prepared;
  final BackupFailure? failure;
  final DataTransferSuccess success;
  final bool autoStartRepairRequired;
  final bool refreshRequired;

  bool get isBusy =>
      phase == DataTransferPhase.exporting ||
      phase == DataTransferPhase.preparing ||
      phase == DataTransferPhase.confirming;
}
