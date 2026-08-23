import 'package:drift/drift.dart';

import '../../../../contexts/todo/public.dart'
    show Todo, TodoMutation, TodoMutationResult, TodoRepository;
import '../clock_rhythm_database.dart';
import '../mappers/todo_record_mapper.dart';

final class DriftTodoRepository implements TodoRepository {
  const DriftTodoRepository(this._database);

  final ClockRhythmDatabase _database;

  @override
  Future<List<Todo>> getAll() {
    return _readAll();
  }

  @override
  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation) {
    return _database.transaction(() async {
      final TodoMutationResult<T> result = mutation(await _readAll());
      await _writeAll(result.todos);
      return result.value;
    });
  }

  @override
  Future<void> saveAll(List<Todo> todos) {
    return _database.transaction(() => _writeAll(todos));
  }

  Future<List<Todo>> _readAll() async {
    final List<TodoRecord> records =
        await (_database.select(_database.todoRecords)
              ..orderBy(<OrderingTerm Function(TodoRecords)>[
                (TodoRecords table) => OrderingTerm.asc(table.storageOrder),
              ]))
            .get();
    if (records.length > Todo.maximumInstallationCount) {
      throw const FormatException(
        'Todo installation count exceeds the supported maximum.',
      );
    }
    for (int index = 0; index < records.length; index += 1) {
      if (records[index].storageOrder != index) {
        throw const FormatException(
          'Todo storage order must be one contiguous sequence.',
        );
      }
    }
    return List<Todo>.unmodifiable(records.map(TodoRecordMapper.restore));
  }

  Future<void> _writeAll(List<Todo> todos) async {
    final List<TodoRecordsCompanion> rows = <TodoRecordsCompanion>[
      for (int index = 0; index < todos.length; index += 1)
        TodoRecordMapper.toCompanion(todos[index], index),
    ];
    await _database.delete(_database.todoRecords).go();
    if (rows.isNotEmpty) {
      await _database.batch((Batch batch) {
        batch.insertAll(_database.todoRecords, rows);
      });
    }
  }
}
