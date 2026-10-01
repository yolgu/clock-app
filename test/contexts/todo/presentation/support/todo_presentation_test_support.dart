import 'dart:async';

import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class TestTodoRepository implements TodoRepository {
  TestTodoRepository([Iterable<Todo> initialTodos = const <Todo>[]])
    : todos = List<Todo>.of(initialTodos, growable: false);

  List<Todo> todos;
  int getAllCalls = 0;
  int mutateCalls = 0;
  int saveAllCalls = 0;
  bool failMutations = false;

  @override
  Future<List<Todo>> getAll() async {
    getAllCalls += 1;
    return List<Todo>.of(todos, growable: false);
  }

  @override
  Future<void> saveAll(List<Todo> todos) async {
    saveAllCalls += 1;
    this.todos = List<Todo>.of(todos, growable: false);
  }

  @override
  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation) async {
    mutateCalls += 1;
    if (failMutations) {
      throw StateError('injected Todo mutation failure');
    }
    final TodoMutationResult<T> result = mutation(
      List<Todo>.of(todos, growable: false),
    );
    todos = List<Todo>.of(result.todos, growable: false);
    return result.value;
  }
}

final class TestApplicationClock implements Clock {
  TestApplicationClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

final class TestTodoDateClock implements TodoDateClock {
  TestTodoDateClock(this.current);

  DateTime current;
  final StreamController<DateTime> _changes =
      StreamController<DateTime>.broadcast(sync: true);

  @override
  Stream<DateTime> get localDateChanges => _changes.stream;

  @override
  DateTime now() => current;

  void moveTo(DateTime value) {
    current = value;
    _changes.add(value);
  }

  void dispose() {
    unawaited(_changes.close());
  }
}

final class SequenceTodoIdGenerator implements TodoIdGenerator {
  int _next = 1;

  @override
  String nextId() {
    final String id = 'created-${_next.toString()}';
    _next += 1;
    return id;
  }
}

TodoPresentationDependencies createTodoPresentationDependencies({
  required TodoRepository repository,
  TestApplicationClock? applicationClock,
  TodoIdGenerator? idGenerator,
}) {
  final TestApplicationClock clock =
      applicationClock ?? TestApplicationClock(DateTime.utc(2026, 6, 2));
  return TodoPresentationDependencies(
    createTodo: CreateTodo(
      repository: repository,
      idGenerator: idGenerator ?? SequenceTodoIdGenerator(),
      clock: clock,
    ),
    updateTodo: UpdateTodo(repository: repository, clock: clock),
    toggleTodoCompletion: ToggleTodoCompletion(
      repository: repository,
      clock: clock,
    ),
    reorderTodos: ReorderTodos(repository: repository, clock: clock),
    deleteTodo: DeleteTodo(repository: repository),
    listTodosForDate: ListTodosForDate(repository: repository),
    listMonthSummary: ListMonthSummary(repository: repository),
  );
}

Widget buildTodoTestApp({
  required TestTodoRepository repository,
  required TestTodoDateClock dateClock,
  required Widget child,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: [
      todoPresentationDependenciesProvider.overrideWithValue(
        createTodoPresentationDependencies(repository: repository),
      ),
      todoDateClockProvider.overrideWithValue(dateClock),
    ],
    child: MaterialApp(
      restorationScopeId: 'todo-test-app',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme:
          theme ??
          ClockRhythmTheme.build(
            ThemeCatalog.resolve(ThemePreference.current),
            platform: TargetPlatform.android,
          ),
      builder: (BuildContext context, Widget? appChild) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: appChild ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(body: child),
    ),
  );
}

Todo createTestTodo({
  required String id,
  required String title,
  String date = '2026-06-02',
  String? time,
  int displayOrder = 0,
  bool completed = false,
}) {
  Todo todo = Todo.create(
    id: TodoId.parse(id),
    title: TodoTitle.parse(title),
    date: LocalCalendarDate.parse(date),
    time: TodoTime.optional(time),
    displayOrder: displayOrder,
    createdAt: DateTime.utc(2026, 6, 2, 0, displayOrder),
  );
  if (completed) {
    todo = todo.complete(DateTime.utc(2026, 6, 2, 1, displayOrder));
  }
  return todo;
}
