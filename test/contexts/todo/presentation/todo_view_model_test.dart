import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/todo_presentation_test_support.dart';

void main() {
  test(
    'loads both completion groups without sorting by optional time',
    () async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(
          id: 'late',
          title: 'Late label',
          time: '23:00',
          displayOrder: 0,
        ),
        createTestTodo(
          id: 'early',
          title: 'Early label',
          time: '06:00',
          displayOrder: 1,
        ),
        createTestTodo(id: 'done', title: 'Completed', completed: true),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2, 10),
      );
      final ProviderContainer container = _createContainer(
        repository,
        dateClock,
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);

      final TodoViewState state = await container.read(
        todoViewModelProvider.future,
      );

      expect(state.todayTodos.map((TodoSnapshot todo) => todo.id), <String>[
        'late',
        'early',
        'done',
      ]);
      expect(state.todayTodos.last.completed, isTrue);
      expect(
        state.monthSummary['2026-06-02'],
        const TodoDaySummary(total: 3, completed: 1),
      );
    },
  );

  test(
    'creates, completes, reopens, and permanently deletes through commands',
    () async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'existing', title: 'Existing'),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2, 10),
      );
      final ProviderContainer container = _createContainer(
        repository,
        dateClock,
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      await container.read(todoViewModelProvider.future);
      final TodoViewModel viewModel = container.read(
        todoViewModelProvider.notifier,
      );

      expect(
        await viewModel.createTodo(
          title: '  New Todo  ',
          date: LocalCalendarDate.parse('2026-06-02'),
          time: '23:45',
        ),
        isTrue,
      );
      TodoViewState state = container.read(todoViewModelProvider).requireValue;
      final TodoSnapshot created = state.todayTodos.singleWhere(
        (TodoSnapshot todo) => todo.id.startsWith('created-'),
      );
      expect(created.title, 'New Todo');
      expect(created.time, '23:45');

      expect(await viewModel.toggleTodo(created), isTrue);
      state = container.read(todoViewModelProvider).requireValue;
      TodoSnapshot toggled = state.todayTodos.singleWhere(
        (TodoSnapshot todo) => todo.id == created.id,
      );
      expect(toggled.completed, isTrue);
      expect(state.message, TodoUiMessage.completed);

      expect(await viewModel.toggleTodo(toggled), isTrue);
      state = container.read(todoViewModelProvider).requireValue;
      toggled = state.todayTodos.singleWhere(
        (TodoSnapshot todo) => todo.id == created.id,
      );
      expect(toggled.completed, isFalse);
      expect(state.message, TodoUiMessage.reopened);

      expect(await viewModel.deleteTodo(toggled), isTrue);
      state = container.read(todoViewModelProvider).requireValue;
      expect(
        state.todayTodos.any((TodoSnapshot todo) => todo.id == created.id),
        isFalse,
      );
      expect(state.message, TodoUiMessage.deleted);
      expect(repository.mutateCalls, 4);
    },
  );

  test(
    'edits title, date, and time with exactly one UpdateTodo mutation',
    () async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'editing', title: 'Before'),
        createTestTodo(
          id: 'target',
          title: 'Target',
          date: '2026-06-03',
          displayOrder: 7,
        ),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2, 10),
      );
      final ProviderContainer container = _createContainer(
        repository,
        dateClock,
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      final TodoViewState initial = await container.read(
        todoViewModelProvider.future,
      );
      final TodoSnapshot editing = initial.todayTodos.single;
      final int mutationsBeforeEdit = repository.mutateCalls;

      final bool succeeded = await container
          .read(todoViewModelProvider.notifier)
          .updateTodo(
            todo: editing,
            title: ' After ',
            date: LocalCalendarDate.parse('2026-06-03'),
            time: '08:05',
          );

      expect(succeeded, isTrue);
      expect(repository.mutateCalls - mutationsBeforeEdit, 1);
      final Todo moved = repository.todos.singleWhere(
        (Todo todo) => todo.id.text == 'editing',
      );
      expect(moved.title.text, 'After');
      expect(moved.date.text, '2026-06-03');
      expect(moved.time?.text, '08:05');
      expect(moved.displayOrder, 8);
    },
  );

  test(
    'accessible move commands submit a full same-group permutation',
    () async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'a', title: 'A', displayOrder: 0),
        createTestTodo(id: 'b', title: 'B', displayOrder: 1),
        createTestTodo(id: 'c', title: 'C', displayOrder: 2),
        createTestTodo(id: 'done', title: 'Done', completed: true),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2, 10),
      );
      final ProviderContainer container = _createContainer(
        repository,
        dateClock,
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      final TodoViewState initial = await container.read(
        todoViewModelProvider.future,
      );

      expect(
        await container
            .read(todoViewModelProvider.notifier)
            .moveTodoDown(initial.todayTodos.first),
        isTrue,
      );

      final TodoViewState state = container
          .read(todoViewModelProvider)
          .requireValue;
      expect(state.todayTodos.map((TodoSnapshot todo) => todo.id), <String>[
        'b',
        'a',
        'c',
        'done',
      ]);
      expect(
        repository.todos
            .where((Todo todo) => !todo.completionGroup.isCompleted)
            .map((Todo todo) => todo.displayOrder),
        unorderedEquals(<int>[0, 1, 2]),
      );
      expect(repository.mutateCalls, 1);
    },
  );

  test(
    'midnight follows old today but preserves an explicit selected date',
    () async {
      final TestTodoRepository repository = TestTodoRepository();
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 30, 23, 59),
      );
      final ProviderContainer container = _createContainer(
        repository,
        dateClock,
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      await container.read(todoViewModelProvider.future);
      final TodoViewModel viewModel = container.read(
        todoViewModelProvider.notifier,
      );

      await viewModel.reconcileLocalDate(DateTime(2026, 7, 1));
      TodoViewState state = container.read(todoViewModelProvider).requireValue;
      expect(state.todayDate.text, '2026-07-01');
      expect(state.selectedDate.text, '2026-07-01');
      expect(state.visibleMonth.monthKey, '2026-07');

      await viewModel.selectDate(LocalCalendarDate.parse('2026-07-05'));
      await viewModel.reconcileLocalDate(DateTime(2026, 7, 2));
      state = container.read(todoViewModelProvider).requireValue;
      expect(state.todayDate.text, '2026-07-02');
      expect(state.selectedDate.text, '2026-07-05');
    },
  );

  test(
    'month rollover keeps a user-selected date and its visible month',
    () async {
      final TestTodoRepository repository = TestTodoRepository();
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 30, 23, 59),
      );
      final ProviderContainer container = _createContainer(
        repository,
        dateClock,
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      await container.read(todoViewModelProvider.future);
      final TodoViewModel viewModel = container.read(
        todoViewModelProvider.notifier,
      );

      await viewModel.selectDate(LocalCalendarDate.parse('2026-06-05'));
      await viewModel.reconcileLocalDate(DateTime(2026, 7, 1));

      final TodoViewState state = container
          .read(todoViewModelProvider)
          .requireValue;
      expect(state.todayDate.text, '2026-07-01');
      expect(state.selectedDate.text, '2026-06-05');
      expect(state.visibleMonth.monthKey, '2026-06');
    },
  );

  test(
    'reacts to the dedicated local-date stream without a one-second tick',
    () async {
      final TestTodoRepository repository = TestTodoRepository();
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2, 23, 59),
      );
      final ProviderContainer container = _createContainer(
        repository,
        dateClock,
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      await container.read(todoViewModelProvider.future);
      await pumpEventQueue();

      dateClock.moveTo(DateTime(2026, 6, 3));
      await pumpEventQueue();

      final TodoViewState state = container
          .read(todoViewModelProvider)
          .requireValue;
      expect(state.todayDate.text, '2026-06-03');
      expect(state.selectedDate.text, '2026-06-03');
    },
  );

  test(
    'maps the installation limit to a stable presentation message',
    () async {
      final _LimitTodoRepository repository = _LimitTodoRepository();
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          todoPresentationDependenciesProvider.overrideWithValue(
            createTodoPresentationDependencies(repository: repository),
          ),
          todoDateClockProvider.overrideWithValue(dateClock),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      await container.read(todoViewModelProvider.future);

      final bool succeeded = await container
          .read(todoViewModelProvider.notifier)
          .createTodo(
            title: 'Over limit',
            date: LocalCalendarDate.parse('2026-06-02'),
            time: null,
          );

      expect(succeeded, isFalse);
      expect(
        container.read(todoViewModelProvider).requireValue.message,
        TodoUiMessage.limitReached,
      );
    },
  );

  test(
    'hides stale actions when a successful mutation cannot refresh',
    () async {
      final _FailingRefreshTodoRepository repository =
          _FailingRefreshTodoRepository();
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          todoPresentationDependenciesProvider.overrideWithValue(
            createTodoPresentationDependencies(repository: repository),
          ),
          todoDateClockProvider.overrideWithValue(dateClock),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(dateClock.dispose);
      await container.read(todoViewModelProvider.future);

      final bool commandSucceeded = await container
          .read(todoViewModelProvider.notifier)
          .createTodo(
            title: 'Persisted',
            date: LocalCalendarDate.parse('2026-06-02'),
            time: null,
          );

      expect(commandSucceeded, isTrue);
      expect(repository.todos.single.title.text, 'Persisted');
      expect(
        container.read(todoViewModelProvider),
        isA<AsyncError<TodoViewState>>(),
      );
    },
  );
}

ProviderContainer _createContainer(
  TestTodoRepository repository,
  TestTodoDateClock dateClock,
) {
  return ProviderContainer(
    overrides: [
      todoPresentationDependenciesProvider.overrideWithValue(
        createTodoPresentationDependencies(repository: repository),
      ),
      todoDateClockProvider.overrideWithValue(dateClock),
    ],
  );
}

final class _LimitTodoRepository implements TodoRepository {
  @override
  Future<List<Todo>> getAll() async => const <Todo>[];

  @override
  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation) {
    throw const TodoLimitReachedFailure(
      actualCount: Todo.maximumInstallationCount,
      maximumCount: Todo.maximumInstallationCount,
    );
  }

  @override
  Future<void> saveAll(List<Todo> todos) async {}
}

final class _FailingRefreshTodoRepository implements TodoRepository {
  List<Todo> todos = <Todo>[];
  bool _failReads = false;

  @override
  Future<List<Todo>> getAll() async {
    if (_failReads) {
      throw StateError('read unavailable');
    }
    return List<Todo>.of(todos, growable: false);
  }

  @override
  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation) async {
    final TodoMutationResult<T> result = mutation(
      List<Todo>.of(todos, growable: false),
    );
    todos = List<Todo>.of(result.todos, growable: false);
    _failReads = true;
    return result.value;
  }

  @override
  Future<void> saveAll(List<Todo> todos) async {
    this.todos = List<Todo>.of(todos, growable: false);
  }
}
