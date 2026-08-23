import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_failure.dart';
import 'ports/todo_repository.dart';

final class ReplaceTodoSnapshots {
  const ReplaceTodoSnapshots({required TodoRepository repository})
    : this._(repository);

  const ReplaceTodoSnapshots._(this._repository);

  final TodoRepository _repository;

  Future<void> execute(List<TodoRestoreSnapshot> snapshots) async {
    if (snapshots.length > TodoCollection.maximumTodos) {
      throw TodoLimitReachedFailure(
        actualCount: snapshots.length,
        maximumCount: TodoCollection.maximumTodos,
      );
    }
    final List<Todo> restored = snapshots
        .map(Todo.restore)
        .toList(growable: false);
    final TodoCollection collection = TodoCollection.from(restored);
    await _repository.saveAll(collection.todos);
  }
}
