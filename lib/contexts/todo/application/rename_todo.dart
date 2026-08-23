import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_id.dart';
import '../domain/todo_title.dart';
import 'ports/clock.dart';
import 'ports/todo_repository.dart';

final class RenameTodoCommand {
  const RenameTodoCommand({required this.id, required this.title});

  final String id;
  final String title;
}

final class RenameTodo {
  const RenameTodo({required TodoRepository repository, required Clock clock})
    : this._(repository, clock);

  const RenameTodo._(this._repository, this._clock);

  final TodoRepository _repository;
  final Clock _clock;

  Future<TodoSnapshot> execute(RenameTodoCommand command) async {
    final TodoId id = TodoId.parse(command.id);
    final TodoTitle title = TodoTitle.parse(command.title);
    return _repository.mutate<TodoSnapshot>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      collection.todoById(id);
      final TodoCollection updated = collection.rename(
        id: id,
        title: title,
        updatedAt: _clock.now(),
      );
      return TodoMutationResult<TodoSnapshot>(
        todos: updated.todos,
        value: updated.todoById(id).snapshot(),
      );
    });
  }
}
