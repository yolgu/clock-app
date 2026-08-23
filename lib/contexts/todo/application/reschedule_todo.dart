import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_id.dart';
import '../domain/todo_time.dart';
import 'ports/clock.dart';
import 'ports/todo_repository.dart';

final class RescheduleTodoCommand {
  const RescheduleTodoCommand({
    required this.id,
    required this.date,
    required this.time,
  });

  final String id;
  final String date;
  final String? time;
}

final class RescheduleTodo {
  const RescheduleTodo({
    required TodoRepository repository,
    required Clock clock,
  }) : this._(repository, clock);

  const RescheduleTodo._(this._repository, this._clock);

  final TodoRepository _repository;
  final Clock _clock;

  Future<TodoSnapshot> execute(RescheduleTodoCommand command) async {
    final TodoId id = TodoId.parse(command.id);
    final LocalCalendarDate date = LocalCalendarDate.parse(command.date);
    final TodoTime? time = TodoTime.optional(command.time);
    return _repository.mutate<TodoSnapshot>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      collection.todoById(id);
      final TodoCollection updated = collection.reschedule(
        id: id,
        date: date,
        time: time,
        updatedAt: _clock.now(),
      );
      return TodoMutationResult<TodoSnapshot>(
        todos: updated.todos,
        value: updated.todoById(id).snapshot(),
      );
    });
  }
}
