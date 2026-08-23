enum BackupFailureKey {
  fileRead('backup.file.read'),
  fileWrite('backup.file.write'),
  fileTooLarge('backup.file.tooLarge'),
  export('backup.export'),
  invalidEncoding('backup.invalidEncoding'),
  invalidJson('backup.invalidJson'),
  appNameMismatch('backup.appNameMismatch'),
  unsupportedSchemaVersion('backup.unsupportedSchemaVersion'),
  invalidExportedAt('backup.invalidExportedAt'),
  missingRequiredData('backup.missingRequiredData'),
  invalidPreferences('backup.invalidPreferences'),
  tooManyTodos('backup.tooManyTodos'),
  todoIdInvalid('backup.todo.id.invalid'),
  todoIdDuplicate('backup.todo.id.duplicate'),
  todoTitleInvalid('backup.todo.title.invalid'),
  todoDateInvalid('backup.todo.date.invalid'),
  todoTimeInvalid('backup.todo.time.invalid'),
  todoCompletionInvalid('backup.todo.completion.invalid'),
  todoTimestampsInvalid('backup.todo.timestamps.invalid'),
  todoDisplayOrderInvalid('backup.todo.displayOrder.invalid'),
  rhythmSafety('backup.rhythmSafety'),
  replacement('backup.replacement');

  const BackupFailureKey(this.stableKey);

  final String stableKey;
}

final class BackupFailure implements Exception {
  const BackupFailure({required this.key, this.zeroBasedTodoIndex});

  final BackupFailureKey key;
  final int? zeroBasedTodoIndex;

  @override
  String toString() {
    final int? index = zeroBasedTodoIndex;
    return index == null
        ? 'BackupFailure(${key.stableKey})'
        : 'BackupFailure(${key.stableKey}, index: $index)';
  }
}
