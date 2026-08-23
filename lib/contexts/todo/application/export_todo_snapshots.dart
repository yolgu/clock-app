import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import 'ports/todo_repository.dart';

final class ExportTodoSnapshots {
  const ExportTodoSnapshots({required TodoRepository repository})
    : this._(repository);

  const ExportTodoSnapshots._(this._repository);

  final TodoRepository _repository;

  Future<List<TodoSnapshot>> execute() async {
    final TodoCollection collection = TodoCollection.from(
      await _repository.getAll(),
    );
    return List<TodoSnapshot>.unmodifiable(
      collection.todos.map((Todo todo) => todo.snapshot()),
    );
  }
}
