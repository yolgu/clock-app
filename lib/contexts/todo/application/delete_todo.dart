import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_id.dart';
import 'ports/todo_repository.dart';

final class DeleteTodo {
  const DeleteTodo({required TodoRepository repository}) : this._(repository);

  const DeleteTodo._(this._repository);

  final TodoRepository _repository;

  Future<void> execute(String rawId) async {
    final TodoId id = TodoId.parse(rawId);
    await _repository.mutate<Null>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      final TodoCollection updated = collection.delete(id);
      return TodoMutationResult<Null>(todos: updated.todos, value: null);
    });
  }
}
