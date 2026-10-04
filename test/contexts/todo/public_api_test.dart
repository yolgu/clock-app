import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports the planned Todo model, ports, snapshots, and use cases', () {
    _acceptType<Todo>();
    _acceptType<TodoId>();
    _acceptType<TodoTitle>();
    _acceptType<LocalCalendarDate>();
    _acceptType<TodoTime>();
    _acceptType<CompletionGroup>();
    _acceptType<TodoSnapshot>();
    _acceptType<TodoRestoreSnapshot>();
    _acceptType<TodoDaySummary>();
    _acceptType<TodoFailure>();
    _acceptType<TodoLimitReachedFailure>();
    _acceptType<TodoNotFoundFailure>();
    _acceptType<TodoIdConflictFailure>();
    _acceptType<InvalidTodoReorderFailure>();
    _acceptType<TodoReorderFailureReason>();
    _acceptType<TodoRepository>();
    _acceptType<TodoIdGenerator>();
    _acceptType<Clock>();
    _acceptType<TodoCommandService>();
    _acceptType<CreateTodoCommand>();
    _acceptType<RenameTodoCommand>();
    _acceptType<RescheduleTodoCommand>();
    _acceptType<ReorderTodosCommand>();
    _acceptType<TodoQueryService>();
    _acceptType<ReplaceTodoSnapshots>();

    expect(TodoTitle.parse('과제').graphemeLength, 2);
    expect(Todo.maximumInstallationCount, 25000);
  });
}

void _acceptType<T>() {}
