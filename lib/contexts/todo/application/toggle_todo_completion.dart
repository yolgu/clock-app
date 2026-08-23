import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_id.dart';
import 'ports/clock.dart';
import 'ports/todo_repository.dart';

final class ToggleTodoCompletion {
  const ToggleTodoCompletion({
    required TodoRepository repository,
    required Clock clock,
  }) : this._(repository, clock);

  const ToggleTodoCompletion._(this._repository, this._clock);

  final TodoRepository _repository;
  final Clock _clock;

  Future<TodoSnapshot> execute(String rawId) async {
    final TodoId id = TodoId.parse(rawId);
    return _repository.mutate<TodoSnapshot>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      collection.todoById(id);
      final TodoCollection updated = collection.toggleCompletion(
        id,
        _clock.now(),
      );
      return TodoMutationResult<TodoSnapshot>(
        todos: updated.todos,
        value: updated.todoById(id).snapshot(),
      );
    });
  }
}
