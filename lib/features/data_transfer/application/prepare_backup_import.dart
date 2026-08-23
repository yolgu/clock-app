import '../../../contexts/preferences/public.dart'
    show GetPreferences, UserPreferences;
import '../../../contexts/todo/public_model.dart' show Todo;
import 'backup_preview.dart';
import 'ports.dart';

final class BackupImportPayload {
  BackupImportPayload({required this.preferences, required List<Todo> todos})
    : todos = List<Todo>.unmodifiable(todos);

  final UserPreferences preferences;
  final List<Todo> todos;
}

final class PreparedBackupImport {
  factory PreparedBackupImport.fromValidatedData({
    required PortableBackupData data,
    required bool currentAutoStartEnabled,
  }) {
    return PreparedBackupImport._(
      preview: _createBackupPreview(data, currentAutoStartEnabled),
      payload: BackupImportPayload(
        preferences: data.preferences,
        todos: data.todos,
      ),
    );
  }

  PreparedBackupImport._({required this.preview, required this.payload});

  final BackupPreview preview;
  final BackupImportPayload payload;
}

final class PrepareBackupImport {
  factory PrepareBackupImport({
    required BackupFilePort backupFile,
    required PortableBackupCodec codec,
    required GetPreferences getPreferences,
  }) {
    return PrepareBackupImport._(backupFile, codec, getPreferences);
  }

  const PrepareBackupImport._(
    this._backupFile,
    this._codec,
    this._getPreferences,
  );

  final BackupFilePort _backupFile;
  final PortableBackupCodec _codec;
  final GetPreferences _getPreferences;

  Future<PreparedBackupImport?> execute() async {
    final BackupFileContent? content = await _backupFile.pickImport(
      maximumBytes: _codec.maximumFileBytes,
    );
    if (content == null) {
      return null;
    }
    final PortableBackupData data = _codec.decode(content.bytes);
    final UserPreferences currentPreferences = await _getPreferences.execute();
    return PreparedBackupImport.fromValidatedData(
      data: data,
      currentAutoStartEnabled: currentPreferences.autoStartEnabled,
    );
  }
}

BackupPreview _createBackupPreview(
  PortableBackupData data,
  bool currentAutoStartEnabled,
) {
  final List<String> dates =
      data.todos.map((Todo todo) => todo.date.text).toList(growable: false)
        ..sort();
  final UserPreferences imported = data.preferences;
  return BackupPreview(
    exportedAt: data.exportedAt,
    todoCount: data.todos.length,
    completedTodoCount: data.todos
        .where((Todo todo) => todo.completionGroup.isCompleted)
        .length,
    earliestTodoDate: dates.firstOrNull,
    latestTodoDate: dates.lastOrNull,
    focusMinutes: imported.rhythmConfiguration.focusDuration.minutes,
    restMinutes: imported.rhythmConfiguration.restDuration.minutes,
    dailyStart: imported.rhythmConfiguration.dailyRhythm.start.text,
    dailyEnd: imported.rhythmConfiguration.dailyRhythm.end.text,
    languageId: imported.language.id,
    themeId: imported.theme.id,
    autoStartEnabled: imported.autoStartEnabled,
    autoStartWillChange: imported.autoStartEnabled != currentAutoStartEnabled,
    customSoundWasSanitized: data.customSoundWasSanitized,
  );
}
