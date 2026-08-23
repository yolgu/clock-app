import 'backup_failure.dart';
import 'ports.dart';
import 'prepare_backup_import.dart';

final class ConfirmBackupImportResult {
  const ConfirmBackupImportResult({required this.autoStartRepairRequired});

  final bool autoStartRepairRequired;
}

final class ConfirmBackupImport {
  factory ConfirmBackupImport({
    required RhythmSafetyPort rhythmSafety,
    required BackupReplacementPort replacement,
  }) {
    return ConfirmBackupImport._(rhythmSafety, replacement);
  }

  const ConfirmBackupImport._(this._rhythmSafety, this._replacement);

  final RhythmSafetyPort _rhythmSafety;
  final BackupReplacementPort _replacement;

  Future<ConfirmBackupImportResult> execute(
    PreparedBackupImport prepared,
  ) async {
    try {
      await _rhythmSafety.stopForImport();
    } on Object {
      throw const BackupFailure(key: BackupFailureKey.rhythmSafety);
    }
    try {
      final BackupReplacementResult result = await _replacement.replaceAll(
        preferences: prepared.payload.preferences,
        todos: prepared.payload.todos,
      );
      return ConfirmBackupImportResult(
        autoStartRepairRequired: result.autoStartRepairRequired,
      );
    } on BackupFailure {
      rethrow;
    } on Object {
      throw const BackupFailure(key: BackupFailureKey.replacement);
    }
  }
}
