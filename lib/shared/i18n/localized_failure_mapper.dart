import '../../l10n/generated/app_localizations.dart';

enum LocalizedFailureKey {
  unknown('failure.unknown'),
  routeNotFound('route.notFound'),
  routeInvalidCalendarDate('route.invalidCalendarDate'),
  preferencesSave('preferences.save'),
  todoLimitReached('todo.limitReached'),
  todoAction('todo.action'),
  customSoundInvalidFile('sound.custom.invalidFile'),
  customSoundTooLarge('sound.custom.tooLarge'),
  customSoundDecode('sound.custom.decode'),
  customSoundPlayback('sound.custom.playback'),
  autoStartReconciliation('preferences.autoStart.reconciliation'),
  backupFileRead('backup.file.read'),
  backupFileWrite('backup.file.write'),
  backupFileTooLarge('backup.file.tooLarge'),
  backupInvalidJson('backup.invalidJson'),
  backupAppNameMismatch('backup.appNameMismatch'),
  backupUnsupportedSchemaVersion('backup.unsupportedSchemaVersion'),
  backupInvalidExportedAt('backup.invalidExportedAt'),
  backupMissingRequiredData('backup.missingRequiredData'),
  backupInvalidPreferences('backup.invalidPreferences'),
  backupTooManyTodos('backup.tooManyTodos'),
  backupReplacement('backup.replacement'),
  backupExport('backup.export'),
  databaseOpen('database.open'),
  databaseMigration('database.migration'),
  databaseCorrupted('database.corrupted'),
  databaseRecoveryCopy('database.recoveryCopy'),
  notificationPermissionRequired('permission.notification.required'),
  exactAlarmPermissionRequired('permission.exactAlarm.required'),
  notificationAndExactAlarmPermissionRequired(
    'permission.notificationAndExactAlarm.required',
  ),
  deliveryPermissionLost('delivery.permissionLost'),
  deliveryRecoveryRequired('delivery.recoveryRequired');

  const LocalizedFailureKey(this.stableKey);

  final String stableKey;
}

enum IndexedBackupFailureKey {
  todoIdInvalid('backup.todo.id.invalid'),
  todoIdDuplicate('backup.todo.id.duplicate'),
  todoTitleInvalid('backup.todo.title.invalid'),
  todoDateInvalid('backup.todo.date.invalid'),
  todoTimeInvalid('backup.todo.time.invalid'),
  todoCompletionInvalid('backup.todo.completion.invalid'),
  todoTimestampsInvalid('backup.todo.timestamps.invalid'),
  todoDisplayOrderInvalid('backup.todo.displayOrder.invalid');

  const IndexedBackupFailureKey(this.stableKey);

  final String stableKey;
}

final class LocalizedFailureMapper {
  const LocalizedFailureMapper(this._localizations);

  final AppLocalizations _localizations;

  String message(LocalizedFailureKey key) {
    return switch (key) {
      LocalizedFailureKey.unknown => _localizations.failureUnknown,
      LocalizedFailureKey.routeNotFound => _localizations.failureRouteNotFound,
      LocalizedFailureKey.routeInvalidCalendarDate =>
        _localizations.failureRouteInvalidCalendarDate,
      LocalizedFailureKey.preferencesSave =>
        _localizations.failurePreferencesSave,
      LocalizedFailureKey.todoLimitReached =>
        _localizations.failureTodoLimitReached,
      LocalizedFailureKey.todoAction => _localizations.failureTodoAction,
      LocalizedFailureKey.customSoundInvalidFile =>
        _localizations.failureCustomSoundInvalidFile,
      LocalizedFailureKey.customSoundTooLarge =>
        _localizations.failureCustomSoundTooLarge,
      LocalizedFailureKey.customSoundDecode =>
        _localizations.failureCustomSoundDecode,
      LocalizedFailureKey.customSoundPlayback =>
        _localizations.failureCustomSoundPlayback,
      LocalizedFailureKey.autoStartReconciliation =>
        _localizations.failureAutoStartReconciliation,
      LocalizedFailureKey.backupFileRead =>
        _localizations.failureBackupFileRead,
      LocalizedFailureKey.backupFileWrite =>
        _localizations.failureBackupFileWrite,
      LocalizedFailureKey.backupFileTooLarge =>
        _localizations.failureBackupFileTooLarge,
      LocalizedFailureKey.backupInvalidJson =>
        _localizations.failureBackupInvalidJson,
      LocalizedFailureKey.backupAppNameMismatch =>
        _localizations.failureBackupAppNameMismatch,
      LocalizedFailureKey.backupUnsupportedSchemaVersion =>
        _localizations.failureBackupUnsupportedSchemaVersion,
      LocalizedFailureKey.backupInvalidExportedAt =>
        _localizations.failureBackupInvalidExportedAt,
      LocalizedFailureKey.backupMissingRequiredData =>
        _localizations.failureBackupMissingRequiredData,
      LocalizedFailureKey.backupInvalidPreferences =>
        _localizations.failureBackupInvalidPreferences,
      LocalizedFailureKey.backupTooManyTodos =>
        _localizations.failureBackupTooManyTodos,
      LocalizedFailureKey.backupReplacement =>
        _localizations.failureBackupReplacement,
      LocalizedFailureKey.backupExport => _localizations.failureBackupExport,
      LocalizedFailureKey.databaseOpen => _localizations.failureDatabaseOpen,
      LocalizedFailureKey.databaseMigration =>
        _localizations.failureDatabaseMigration,
      LocalizedFailureKey.databaseCorrupted =>
        _localizations.failureDatabaseCorrupted,
      LocalizedFailureKey.databaseRecoveryCopy =>
        _localizations.failureDatabaseRecoveryCopy,
      LocalizedFailureKey.notificationPermissionRequired =>
        _localizations.failureNotificationPermissionRequired,
      LocalizedFailureKey.exactAlarmPermissionRequired =>
        _localizations.failureExactAlarmPermissionRequired,
      LocalizedFailureKey.notificationAndExactAlarmPermissionRequired =>
        _localizations.failureNotificationAndExactAlarmPermissionRequired,
      LocalizedFailureKey.deliveryPermissionLost =>
        _localizations.failureDeliveryPermissionLost,
      LocalizedFailureKey.deliveryRecoveryRequired =>
        _localizations.failureDeliveryRecoveryRequired,
    };
  }

  String indexedBackupMessage(
    IndexedBackupFailureKey key, {
    required int zeroBasedIndex,
  }) {
    if (zeroBasedIndex < 0) {
      throw RangeError.range(zeroBasedIndex, 0, null, 'zeroBasedIndex');
    }
    final int displayIndex = zeroBasedIndex + 1;
    return switch (key) {
      IndexedBackupFailureKey.todoIdInvalid =>
        _localizations.failureBackupTodoIdInvalid(displayIndex),
      IndexedBackupFailureKey.todoIdDuplicate =>
        _localizations.failureBackupTodoIdDuplicate(displayIndex),
      IndexedBackupFailureKey.todoTitleInvalid =>
        _localizations.failureBackupTodoTitleInvalid(displayIndex),
      IndexedBackupFailureKey.todoDateInvalid =>
        _localizations.failureBackupTodoDateInvalid(displayIndex),
      IndexedBackupFailureKey.todoTimeInvalid =>
        _localizations.failureBackupTodoTimeInvalid(displayIndex),
      IndexedBackupFailureKey.todoCompletionInvalid =>
        _localizations.failureBackupTodoCompletionInvalid(displayIndex),
      IndexedBackupFailureKey.todoTimestampsInvalid =>
        _localizations.failureBackupTodoTimestampsInvalid(displayIndex),
      IndexedBackupFailureKey.todoDisplayOrderInvalid =>
        _localizations.failureBackupTodoDisplayOrderInvalid(displayIndex),
    };
  }
}
