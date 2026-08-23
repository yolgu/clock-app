import 'package:drift/drift.dart';

import '../../../../contexts/todo/public_model.dart';
import '../clock_rhythm_database.dart';

abstract final class TodoRecordMapper {
  static Todo restore(TodoRecord record) {
    if (record.storageOrder < 0) {
      throw const FormatException('Todo storage order must be nonnegative.');
    }
    return Todo.restore(
      TodoRestoreSnapshot(
        id: record.id,
        title: record.title,
        date: record.localDate,
        time: record.displayTime,
        completed: record.completed,
        displayOrder: record.displayOrder,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
      ),
    );
  }

  static TodoRecordsCompanion toCompanion(Todo todo, int storageOrder) {
    if (storageOrder < 0) {
      throw ArgumentError.value(
        storageOrder,
        'storageOrder',
        'must be nonnegative',
      );
    }
    final TodoSnapshot snapshot = todo.snapshot();
    return TodoRecordsCompanion.insert(
      id: snapshot.id,
      title: snapshot.title,
      localDate: snapshot.date,
      displayTime: Value<String?>(snapshot.time),
      completed: snapshot.completed,
      displayOrder: snapshot.displayOrder,
      createdAt: snapshot.createdAt,
      updatedAt: snapshot.updatedAt,
      storageOrder: storageOrder,
    );
  }
}
