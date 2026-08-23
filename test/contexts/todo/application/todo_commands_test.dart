import 'package:clock_rhythm/contexts/todo/application/create_todo.dart';
import 'package:clock_rhythm/contexts/todo/application/delete_todo.dart';
import 'package:clock_rhythm/contexts/todo/application/ports/clock.dart';
import 'package:clock_rhythm/contexts/todo/application/ports/todo_id_generator.dart';
import 'package:clock_rhythm/contexts/todo/application/ports/todo_repository.dart';
import 'package:clock_rhythm/contexts/todo/application/rename_todo.dart';
import 'package:clock_rhythm/contexts/todo/application/reorder_todos.dart';
import 'package:clock_rhythm/contexts/todo/application/reschedule_todo.dart';
import 'package:clock_rhythm/contexts/todo/application/toggle_todo_completion.dart';
import 'package:clock_rhythm/contexts/todo/application/update_todo.dart';
import 'package:clock_rhythm/contexts/todo/domain/completion_group.dart';
import 'package:clock_rhythm/contexts/todo/domain/local_calendar_date.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_collection.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_failure.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_id.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_time.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates at the end of the target incomplete group', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'incomplete', order: 4),
      _todo(id: 'completed', order: 100).complete(DateTime.utc(2026, 6, 2, 1)),
    ]);
    final RecordingTodoIdGenerator idGenerator = RecordingTodoIdGenerator(
      'created',
    );
    final RecordingClock clock = RecordingClock(DateTime.utc(2026, 6, 2, 2));
    final CreateTodo useCase = CreateTodo(
      repository: repository,
      idGenerator: idGenerator,
      clock: clock,
    );

    final TodoSnapshot created = await useCase.execute(
      const CreateTodoCommand(title: '  추가  ', date: '2026-06-02'),
    );

    expect(created.id, 'created');
    expect(created.title, '추가');
    expect(created.displayOrder, 5);
    expect(created.completed, isFalse);
    expect(idGenerator.calls, 1);
    expect(clock.calls, 1);
    expect(repository.saveCalls, 1);
  });

  test(
    'rejects the 25,001st create before ID, clock, or save effects',
    () async {
      final List<Todo> fullInstallation = List<Todo>.generate(
        TodoCollection.maximumTodos,
        (int index) => _todo(id: 'todo-$index'),
        growable: false,
      );
      final MemoryTodoRepository repository = MemoryTodoRepository(
        fullInstallation,
      );
      final RecordingTodoIdGenerator idGenerator = RecordingTodoIdGenerator(
        'over-limit',
      );
      final RecordingClock clock = RecordingClock(DateTime.utc(2026, 6, 2, 2));
      final CreateTodo useCase = CreateTodo(
        repository: repository,
        idGenerator: idGenerator,
        clock: clock,
      );

      await expectLater(
        useCase.execute(
          const CreateTodoCommand(
            title: '추가할 수 없음',
            date: '2026-06-02',
            time: null,
          ),
        ),
        throwsA(isA<TodoLimitReachedFailure>()),
      );

      expect(idGenerator.calls, 0);
      expect(clock.calls, 0);
      expect(repository.saveCalls, 0);
      expect(repository.todos, hasLength(TodoCollection.maximumTodos));
    },
  );

  test('renames without changing date, time, completion, or order', () async {
    final Todo existing = _todo(
      id: 'todo-1',
      order: 8,
      time: '09:00',
    ).complete(DateTime.utc(2026, 6, 2, 1));
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      existing,
    ]);
    final RenameTodo useCase = RenameTodo(
      repository: repository,
      clock: RecordingClock(DateTime.utc(2026, 6, 2, 2)),
    );

    final TodoSnapshot renamed = await useCase.execute(
      const RenameTodoCommand(id: 'todo-1', title: '  새 이름  '),
    );

    expect(renamed.title, '새 이름');
    expect(renamed.date, '2026-06-02');
    expect(renamed.time, '09:00');
    expect(renamed.completed, isTrue);
    expect(renamed.displayOrder, 8);
  });

  test('reports a missing Todo without reading the Clock or saving', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[]);
    final RecordingClock clock = RecordingClock(DateTime.utc(2026, 6, 2, 2));
    final RenameTodo useCase = RenameTodo(repository: repository, clock: clock);

    await expectLater(
      useCase.execute(const RenameTodoCommand(id: 'missing', title: '새 이름')),
      throwsA(isA<TodoNotFoundFailure>()),
    );

    expect(clock.calls, 0);
    expect(repository.saveCalls, 0);
  });

  test('reschedules to the end of the matching completion group', () async {
    final Todo moving = _todo(
      id: 'moving',
    ).complete(DateTime.utc(2026, 6, 2, 1));
    final Todo targetCompleted = _todo(
      id: 'target-completed',
      date: '2026-06-03',
      order: 2,
    ).complete(DateTime.utc(2026, 6, 2, 1));
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      moving,
      targetCompleted,
      _todo(id: 'target-incomplete', date: '2026-06-03', order: 50),
    ]);
    final RescheduleTodo useCase = RescheduleTodo(
      repository: repository,
      clock: RecordingClock(DateTime.utc(2026, 6, 2, 2)),
    );

    final TodoSnapshot moved = await useCase.execute(
      const RescheduleTodoCommand(
        id: 'moving',
        date: '2026-06-03',
        time: '07:30',
      ),
    );

    expect(moved.date, '2026-06-03');
    expect(moved.time, '07:30');
    expect(moved.completed, isTrue);
    expect(moved.displayOrder, 3);
  });

  test('toggles completion twice while preserving display order', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'todo-1', order: 9),
    ]);
    final ToggleTodoCompletion useCase = ToggleTodoCompletion(
      repository: repository,
      clock: RecordingClock(DateTime.utc(2026, 6, 2, 2)),
    );

    final TodoSnapshot completed = await useCase.execute('todo-1');
    final TodoSnapshot reopened = await useCase.execute('todo-1');

    expect(completed.completed, isTrue);
    expect(reopened.completed, isFalse);
    expect(completed.displayOrder, 9);
    expect(reopened.displayOrder, 9);
  });

  test('persists a full group permutation and returns daily order', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'a', order: 0),
      _todo(id: 'b', order: 1),
      _todo(id: 'done', order: 0).complete(DateTime.utc(2026, 6, 2, 1)),
    ]);
    final ReorderTodos useCase = ReorderTodos(
      repository: repository,
      clock: RecordingClock(DateTime.utc(2026, 6, 2, 2)),
    );

    final List<TodoSnapshot> ordered = await useCase.execute(
      ReorderTodosCommand(
        date: '2026-06-02',
        group: CompletionGroup.incomplete,
        orderedIds: const <String>['b', 'a'],
      ),
    );

    expect(ordered.map((TodoSnapshot todo) => todo.id), <String>[
      'b',
      'a',
      'done',
    ]);
    expect(ordered.map((TodoSnapshot todo) => todo.displayOrder), <int>[
      0,
      1,
      0,
    ]);
  });

  test('does not save an invalid cross-group reorder', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'a'),
      _todo(id: 'done').complete(DateTime.utc(2026, 6, 2, 1)),
    ]);
    final ReorderTodos useCase = ReorderTodos(
      repository: repository,
      clock: RecordingClock(DateTime.utc(2026, 6, 2, 2)),
    );

    await expectLater(
      useCase.execute(
        ReorderTodosCommand(
          date: '2026-06-02',
          group: CompletionGroup.incomplete,
          orderedIds: const <String>['a', 'done'],
        ),
      ),
      throwsA(isA<InvalidTodoReorderFailure>()),
    );

    expect(repository.saveCalls, 0);
  });

  test(
    'deletes permanently and remains idempotent for a stale command',
    () async {
      final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
        _todo(id: 'delete-me'),
      ]);
      final DeleteTodo useCase = DeleteTodo(repository: repository);

      await useCase.execute('delete-me');

      expect(repository.todos, isEmpty);
      expect(repository.saveCalls, 1);
      await useCase.execute('delete-me');
      expect(repository.todos, isEmpty);
      expect(repository.saveCalls, 2);
    },
  );

  test(
    'concurrent creates are serialized without losing either Todo',
    () async {
      final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[]);
      final CreateTodo first = CreateTodo(
        repository: repository,
        idGenerator: RecordingTodoIdGenerator('first'),
        clock: RecordingClock(DateTime.utc(2026, 6, 2)),
      );
      final CreateTodo second = CreateTodo(
        repository: repository,
        idGenerator: RecordingTodoIdGenerator('second'),
        clock: RecordingClock(DateTime.utc(2026, 6, 2, 0, 1)),
      );

      await Future.wait(<Future<TodoSnapshot>>[
        first.execute(
          const CreateTodoCommand(title: 'First', date: '2026-06-02'),
        ),
        second.execute(
          const CreateTodoCommand(title: 'Second', date: '2026-06-02'),
        ),
      ]);

      expect(repository.todos.map((Todo todo) => todo.id.text), <String>[
        'first',
        'second',
      ]);
    },
  );

  test('updates title, date, and time in one repository mutation', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'editing', date: '2026-06-02'),
      _todo(id: 'target', date: '2026-06-03', order: 7),
    ]);
    final UpdateTodo update = UpdateTodo(
      repository: repository,
      clock: RecordingClock(DateTime.utc(2026, 6, 2, 2)),
    );

    final TodoSnapshot result = await update.execute(
      const UpdateTodoCommand(
        id: 'editing',
        title: ' Updated ',
        date: '2026-06-03',
        time: '11:45',
      ),
    );

    expect(result.title, 'Updated');
    expect(result.date, '2026-06-03');
    expect(result.time, '11:45');
    expect(result.displayOrder, 8);
    expect(repository.saveCalls, 1);
  });
}

final class MemoryTodoRepository implements TodoRepository {
  MemoryTodoRepository(Iterable<Todo> todos)
    : todos = List<Todo>.of(todos, growable: false);

  List<Todo> todos;
  int getCalls = 0;
  int saveCalls = 0;

  @override
  Future<List<Todo>> getAll() async {
    getCalls += 1;
    return List<Todo>.of(todos, growable: false);
  }

  @override
  Future<void> saveAll(List<Todo> todos) async {
    saveCalls += 1;
    this.todos = List<Todo>.of(todos, growable: false);
  }

  @override
  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation) async {
    getCalls += 1;
    final TodoMutationResult<T> result = mutation(
      List<Todo>.of(todos, growable: false),
    );
    saveCalls += 1;
    todos = List<Todo>.of(result.todos, growable: false);
    return result.value;
  }
}

final class RecordingTodoIdGenerator implements TodoIdGenerator {
  RecordingTodoIdGenerator(this.id);

  final String id;
  int calls = 0;

  @override
  String nextId() {
    calls += 1;
    return id;
  }
}

final class RecordingClock implements Clock {
  RecordingClock(this.current);

  DateTime current;
  int calls = 0;

  @override
  DateTime now() {
    calls += 1;
    return current;
  }
}

Todo _todo({
  required String id,
  String date = '2026-06-02',
  String? time,
  int order = 0,
}) {
  return Todo.create(
    id: TodoId.parse(id),
    title: TodoTitle.parse('title-$id'),
    date: LocalCalendarDate.parse(date),
    time: TodoTime.optional(time),
    displayOrder: order,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}
