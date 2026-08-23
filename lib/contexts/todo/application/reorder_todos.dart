import '../domain/completion_group.dart';
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_id.dart';
import 'ports/clock.dart';
import 'ports/todo_repository.dart';

final class ReorderTodosCommand {
  ReorderTodosCommand({
    required this.date,
    required this.group,
    required Iterable<String> orderedIds,
  }) : orderedIds = List<String>.unmodifiable(orderedIds);

  final String date;
  final CompletionGroup group;
  final List<String> orderedIds;
}

final class ReorderTodos {
  const ReorderTodos({required TodoRepository repository, required Clock clock})
    : this._(repository, clock);

  const ReorderTodos._(this._repository, this._clock);

  final TodoRepository _repository;
  final Clock _clock;

  Future<List<TodoSnapshot>> execute(ReorderTodosCommand command) async {
    final LocalCalendarDate date = LocalCalendarDate.parse(command.date);
    final List<TodoId> orderedIds = command.orderedIds
        .map(TodoId.parse)
        .toList(growable: false);
    return _repository.mutate<List<TodoSnapshot>>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      final TodoCollection updated = collection.reorder(
        date: date,
        group: command.group,
        orderedIds: orderedIds,
        updatedAt: _clock.now(),
      );
      return TodoMutationResult<List<TodoSnapshot>>(
        todos: updated.todos,
        value: List<TodoSnapshot>.unmodifiable(
          updated.orderedForDate(date).map((Todo todo) => todo.snapshot()),
        ),
      );
    });
  }
}
