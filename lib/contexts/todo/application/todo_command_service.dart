import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_id.dart';
import '../domain/todo_time.dart';
import '../domain/todo_title.dart';
import 'ports/clock.dart';
import 'ports/todo_id_generator.dart';
import 'ports/todo_repository.dart';
import 'todo_commands.dart';

final class TodoCommandService {
  const TodoCommandService({
    required TodoRepository repository,
    required TodoIdGenerator idGenerator,
    required Clock clock,
  }) : this._(repository, idGenerator, clock);

  const TodoCommandService._(this._repository, this._idGenerator, this._clock);

  final TodoRepository _repository;
  final TodoIdGenerator _idGenerator;
  final Clock _clock;

  Future<TodoSnapshot> create(CreateTodoCommand command) async {
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

  Future<TodoSnapshot> rename(RenameTodoCommand command) async {
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

  Future<TodoSnapshot> update(UpdateTodoCommand command) {
    final TodoId id = TodoId.parse(command.id);
    final TodoTitle title = TodoTitle.parse(command.title);
    final LocalCalendarDate date = LocalCalendarDate.parse(command.date);
    final TodoTime? time = TodoTime.optional(command.time);
    return _repository.mutate<TodoSnapshot>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      collection.todoById(id);
      final TodoCollection updated = collection.update(
        id: id,
        title: title,
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

  Future<TodoSnapshot> reschedule(RescheduleTodoCommand command) async {
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

  Future<TodoSnapshot> toggleCompletion(String rawId) async {
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

  Future<void> delete(String rawId) async {
    final TodoId id = TodoId.parse(rawId);
    await _repository.mutate<Null>((List<Todo> currentTodos) {
      final TodoCollection collection = TodoCollection.from(currentTodos);
      final TodoCollection updated = collection.delete(id);
      return TodoMutationResult<Null>(todos: updated.todos, value: null);
    });
  }

  Future<List<TodoSnapshot>> reorder(ReorderTodosCommand command) async {
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
