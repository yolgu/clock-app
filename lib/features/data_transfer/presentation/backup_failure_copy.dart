import '../../../shared/i18n/public.dart';
import '../application/backup_failure.dart';

String backupFailureMessage(AppLocalizations copy, BackupFailure failure) {
  final int? index = failure.zeroBasedTodoIndex;
  return switch (failure.key) {
    BackupFailureKey.fileRead => copy.failureBackupFileRead,
    BackupFailureKey.fileWrite => copy.failureBackupFileWrite,
    BackupFailureKey.fileTooLarge => copy.failureBackupFileTooLarge,
    BackupFailureKey.export => copy.failureBackupExport,
    BackupFailureKey.invalidEncoding ||
    BackupFailureKey.invalidJson => copy.failureBackupInvalidJson,
    BackupFailureKey.appNameMismatch => copy.failureBackupAppNameMismatch,
    BackupFailureKey.unsupportedSchemaVersion =>
      copy.failureBackupUnsupportedSchemaVersion,
    BackupFailureKey.invalidExportedAt => copy.failureBackupInvalidExportedAt,
    BackupFailureKey.missingRequiredData =>
      copy.failureBackupMissingRequiredData,
    BackupFailureKey.invalidPreferences => copy.failureBackupInvalidPreferences,
    BackupFailureKey.tooManyTodos => copy.failureBackupTooManyTodos,
    BackupFailureKey.todoIdInvalid => copy.failureBackupTodoIdInvalid(
      _displayIndex(index),
    ),
    BackupFailureKey.todoIdDuplicate => copy.failureBackupTodoIdDuplicate(
      _displayIndex(index),
    ),
    BackupFailureKey.todoTitleInvalid => copy.failureBackupTodoTitleInvalid(
      _displayIndex(index),
    ),
    BackupFailureKey.todoDateInvalid => copy.failureBackupTodoDateInvalid(
      _displayIndex(index),
    ),
    BackupFailureKey.todoTimeInvalid => copy.failureBackupTodoTimeInvalid(
      _displayIndex(index),
    ),
    BackupFailureKey.todoCompletionInvalid =>
      copy.failureBackupTodoCompletionInvalid(_displayIndex(index)),
    BackupFailureKey.todoTimestampsInvalid =>
      copy.failureBackupTodoTimestampsInvalid(_displayIndex(index)),
    BackupFailureKey.todoDisplayOrderInvalid =>
      copy.failureBackupTodoDisplayOrderInvalid(_displayIndex(index)),
    BackupFailureKey.rhythmSafety => copy.failureDeliveryRecoveryRequired,
    BackupFailureKey.replacement => copy.failureBackupReplacement,
  };
}

int _displayIndex(int? zeroBasedIndex) => (zeroBasedIndex ?? 0) + 1;
