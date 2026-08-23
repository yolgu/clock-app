import 'package:clock_rhythm/contexts/todo/application/export_todo_snapshots.dart';
import 'package:clock_rhythm/contexts/todo/application/list_month_summary.dart';
import 'package:clock_rhythm/contexts/todo/application/list_todos_for_date.dart';
import 'package:clock_rhythm/contexts/todo/application/ports/todo_repository.dart';
import 'package:clock_rhythm/contexts/todo/application/replace_todo_snapshots.dart';
import 'package:clock_rhythm/contexts/todo/domain/local_calendar_date.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_collection.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_failure.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_id.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_time.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists deterministic daily order without Todo Time priority', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'late-time', order: 0, time: '23:00'),
      _todo(id: 'early-time', order: 1, time: '06:00'),
      _todo(id: 'done', order: 0).complete(DateTime.utc(2026, 6, 2, 1)),
    ]);
    final ListTodosForDate useCase = ListTodosForDate(repository: repository);

    final List<TodoSnapshot> todos = await useCase.execute('2026-06-02');

    expect(todos.map((TodoSnapshot todo) => todo.id), <String>[
      'late-time',
      'early-time',
      'done',
    ]);
  });

  test('lists completed and total counts for a valid month', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'a'),
      _todo(id: 'b').complete(DateTime.utc(2026, 6, 2, 1)),
      _todo(id: 'outside', date: '2026-07-01'),
    ]);
    final ListMonthSummary useCase = ListMonthSummary(repository: repository);

    final Map<String, TodoDaySummary> summary = await useCase.execute(
      '2026-06',
    );

    expect(summary['2026-06-02']?.total, 2);
    expect(summary['2026-06-02']?.completed, 1);
    await expectLater(useCase.execute('2026-6'), throwsArgumentError);
  });

  test('exports validated snapshots in repository order', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'b'),
      _todo(id: 'a'),
    ]);
    final ExportTodoSnapshots useCase = ExportTodoSnapshots(
      repository: repository,
    );

    final List<TodoSnapshot> snapshots = await useCase.execute();

    expect(snapshots.map((TodoSnapshot snapshot) => snapshot.id), <String>[
      'b',
      'a',
    ]);
  });

  test('restores every snapshot before one repository replacement', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[
      _todo(id: 'old'),
    ]);
    final ReplaceTodoSnapshots useCase = ReplaceTodoSnapshots(
      repository: repository,
    );

    await useCase.execute(<TodoRestoreSnapshot>[
      const TodoRestoreSnapshot(
        id: 'restored',
        title: '가져온 할 일',
        date: '2028-02-29',
        time: null,
        completed: false,
        displayOrder: null,
        createdAt: '2026-08-22T00:00:00.000Z',
        updatedAt: '2026-08-22T00:00:00.000Z',
      ),
    ]);

    expect(repository.saveCalls, 1);
    expect(repository.todos.single.id.text, 'restored');
    expect(
      repository.todos.single.displayOrder,
      DateTime.parse('2026-08-22T00:00:00.000Z').millisecondsSinceEpoch,
    );
  });

  test(
    'rejects one invalid restore without changing repository state',
    () async {
      final Todo old = _todo(id: 'old');
      final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[old]);
      final ReplaceTodoSnapshots useCase = ReplaceTodoSnapshots(
        repository: repository,
      );

      await expectLater(
        useCase.execute(<TodoRestoreSnapshot>[
          const TodoRestoreSnapshot(
            id: 'valid',
            title: 'valid',
            date: '2026-08-22',
            time: null,
            completed: false,
            displayOrder: 0,
            createdAt: '2026-08-22T00:00:00.000Z',
            updatedAt: '2026-08-22T00:00:00.000Z',
          ),
          const TodoRestoreSnapshot(
            id: 'invalid',
            title: 'invalid',
            date: '2026-02-29',
            time: null,
            completed: false,
            displayOrder: 1,
            createdAt: '2026-08-22T00:00:00.000Z',
            updatedAt: '2026-08-22T00:00:00.000Z',
          ),
        ]),
        throwsArgumentError,
      );

      expect(repository.saveCalls, 0);
      expect(repository.todos, <Todo>[old]);
    },
  );

  test('rejects duplicate restored IDs before replacement', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[]);
    final ReplaceTodoSnapshots useCase = ReplaceTodoSnapshots(
      repository: repository,
    );
    const TodoRestoreSnapshot snapshot = TodoRestoreSnapshot(
      id: 'duplicate',
      title: 'duplicate',
      date: '2026-08-22',
      time: null,
      completed: false,
      displayOrder: 0,
      createdAt: '2026-08-22T00:00:00.000Z',
      updatedAt: '2026-08-22T00:00:00.000Z',
    );

    await expectLater(
      useCase.execute(const <TodoRestoreSnapshot>[snapshot, snapshot]),
      throwsA(isA<TodoIdConflictFailure>()),
    );

    expect(repository.saveCalls, 0);
  });

  test('checks the restore count limit before restoring an item', () async {
    final MemoryTodoRepository repository = MemoryTodoRepository(<Todo>[]);
    final ReplaceTodoSnapshots useCase = ReplaceTodoSnapshots(
      repository: repository,
    );
    const TodoRestoreSnapshot invalidSnapshot = TodoRestoreSnapshot(
      id: '',
      title: '',
      date: '',
      time: null,
      completed: false,
      displayOrder: null,
      createdAt: '',
      updatedAt: '',
    );
    final List<TodoRestoreSnapshot> snapshots =
        List<TodoRestoreSnapshot>.filled(
          TodoCollection.maximumTodos + 1,
          invalidSnapshot,
          growable: false,
        );

    await expectLater(
      useCase.execute(snapshots),
      throwsA(isA<TodoLimitReachedFailure>()),
    );

    expect(repository.saveCalls, 0);
  });
}

final class MemoryTodoRepository implements TodoRepository {
  MemoryTodoRepository(Iterable<Todo> todos)
    : todos = List<Todo>.of(todos, growable: false);

  List<Todo> todos;
  int saveCalls = 0;

  @override
  Future<List<Todo>> getAll() async {
    return List<Todo>.of(todos, growable: false);
  }

  @override
  Future<void> saveAll(List<Todo> todos) async {
    saveCalls += 1;
    this.todos = List<Todo>.of(todos, growable: false);
  }

  @override
  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation) async {
    final TodoMutationResult<T> result = mutation(
      List<Todo>.of(todos, growable: false),
    );
    saveCalls += 1;
    todos = List<Todo>.of(result.todos, growable: false);
    return result.value;
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
