import '../../../contexts/preferences/public.dart'
    show GetPreferences, UserPreferences;
import '../../../contexts/todo/public.dart' show ExportTodoSnapshots;
import '../../../contexts/todo/public_model.dart'
    show Todo, TodoRestoreSnapshot;
import 'ports.dart';

final class ExportPortableBackup {
  factory ExportPortableBackup({
    required GetPreferences getPreferences,
    required ExportTodoSnapshots exportTodos,
    required BackupFilePort backupFile,
    required PortableBackupCodec codec,
    required BackupClock clock,
  }) {
    return ExportPortableBackup._(
      getPreferences,
      exportTodos,
      backupFile,
      codec,
      clock,
    );
  }

  const ExportPortableBackup._(
    this._getPreferences,
    this._exportTodos,
    this._backupFile,
    this._codec,
    this._clock,
  );

  final GetPreferences _getPreferences;
  final ExportTodoSnapshots _exportTodos;
  final BackupFilePort _backupFile;
  final PortableBackupCodec _codec;
  final BackupClock _clock;

  Future<bool> execute() async {
    final UserPreferences preferences = await _getPreferences.execute();
    final List<Todo> todos = (await _exportTodos.execute())
        .map(
          (snapshot) => Todo.restore(
            TodoRestoreSnapshot(
              id: snapshot.id,
              title: snapshot.title,
              date: snapshot.date,
              time: snapshot.time,
              completed: snapshot.completed,
              displayOrder: snapshot.displayOrder,
              createdAt: snapshot.createdAt,
              updatedAt: snapshot.updatedAt,
            ),
          ),
        )
        .toList(growable: false);
    final DateTime exportedAt = _clock.now().toUtc();
    final List<int> bytes = _codec.encode(
      PortableBackupData(
        exportedAt: exportedAt,
        preferences: preferences,
        todos: todos,
        customSoundWasSanitized: false,
      ),
    );
    return _backupFile.saveExport(
      suggestedFileName: _fileName(exportedAt),
      bytes: bytes,
    );
  }

  static String _fileName(DateTime exportedAt) {
    final String compactTimestamp = exportedAt
        .toIso8601String()
        .replaceAll(RegExp('[-:]'), '')
        .replaceAll(RegExp(r'\.\d+Z$'), 'Z');
    return 'clock-rhythm-$compactTimestamp.json';
  }
}
