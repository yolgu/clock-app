import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_id.dart';
import '../domain/todo_time.dart';
import '../domain/todo_title.dart';
import 'ports/clock.dart';
import 'ports/todo_id_generator.dart';
import 'ports/todo_repository.dart';

final class CreateTodoCommand {
  const CreateTodoCommand({required this.title, required this.date, this.time});

  final String title;
  final String date;
  final String? time;
}

final class CreateTodo {
  const CreateTodo({
    required TodoRepository repository,
    required TodoIdGenerator idGenerator,
    required Clock clock,
  }) : this._(repository, idGenerator, clock);

  const CreateTodo._(this._repository, this._idGenerator, this._clock);

  final TodoRepository _repository;
  final TodoIdGenerator _idGenerator;
  final Clock _clock;

  Future<TodoSnapshot> execute(CreateTodoCommand command) async {
    final TodoTitle title = TodoTitle.parse(command.title);
    final LocalCalendarDate date = LocalCalendarDate.parse(command.date);
    final TodoTime? time = TodoTime.optional(command.time);
    return _repository.mutate<TodoSnapshot>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      collection.ensureCanCreate();
      final TodoId id = TodoId.parse(_idGenerator.nextId());
      final TodoCollection updated = collection.createTodo(
        id: id,
        title: title,
        date: date,
        time: time,
        createdAt: _clock.now(),
      );
      return TodoMutationResult<TodoSnapshot>(
        todos: updated.todos,
        value: updated.todoById(id).snapshot(),
      );
    });
  }
}
