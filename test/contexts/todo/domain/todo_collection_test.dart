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
  test(
    'orders incomplete before completed by order, creation, and identifier',
    () {
      final TodoCollection collection = TodoCollection.from(<Todo>[
        _todo(
          id: 'later-id',
          order: 1,
          createdAt: DateTime.utc(2026, 6, 2, 1),
          time: '07:00',
        ),
        _todo(
          id: 'b-id',
          order: 0,
          createdAt: DateTime.utc(2026, 6, 2),
          time: '06:00',
        ),
        _todo(
          id: 'a-id',
          order: 0,
          createdAt: DateTime.utc(2026, 6, 2),
          time: '23:00',
        ),
        _todo(id: 'completed', order: 0).complete(DateTime.utc(2026, 6, 2, 2)),
      ]);

      final List<String> ids = collection
          .orderedForDate(LocalCalendarDate.parse('2026-06-02'))
          .map((Todo todo) => todo.id.text)
          .toList(growable: false);

      expect(ids, <String>['a-id', 'b-id', 'later-id', 'completed']);
    },
  );

  test('completion changes group without changing its display order', () {
    final TodoCollection collection = TodoCollection.from(<Todo>[
      _todo(id: 'todo-1', order: 7),
    ]);

    final TodoCollection completed = collection.toggleCompletion(
      TodoId.parse('todo-1'),
      DateTime.utc(2026, 6, 2, 1),
    );
    final TodoCollection reopened = completed.toggleCompletion(
      TodoId.parse('todo-1'),
      DateTime.utc(2026, 6, 2, 2),
    );

    expect(completed.todoById(TodoId.parse('todo-1')).displayOrder, 7);
    expect(
      completed.todoById(TodoId.parse('todo-1')).completionGroup,
      CompletionGroup.completed,
    );
    expect(reopened.todoById(TodoId.parse('todo-1')).displayOrder, 7);
  });

  test('accepts only a full same-date same-group reorder permutation', () {
    final TodoCollection collection = TodoCollection.from(<Todo>[
      _todo(id: 'a', order: 4),
      _todo(id: 'b', order: 8),
      _todo(id: 'c', order: 9).complete(DateTime.utc(2026, 6, 2, 1)),
      _todo(id: 'other-date', date: '2026-06-03', order: 0),
    ]);

    final TodoCollection reordered = collection.reorder(
      date: LocalCalendarDate.parse('2026-06-02'),
      group: CompletionGroup.incomplete,
      orderedIds: <TodoId>[TodoId.parse('b'), TodoId.parse('a')],
      updatedAt: DateTime.utc(2026, 6, 2, 2),
    );

    expect(reordered.todoById(TodoId.parse('b')).displayOrder, 0);
    expect(reordered.todoById(TodoId.parse('a')).displayOrder, 1);
    expect(reordered.todoById(TodoId.parse('c')).displayOrder, 9);
  });

  test('rejects partial, duplicate, cross-group, and cross-date reorder', () {
    final TodoCollection collection = TodoCollection.from(<Todo>[
      _todo(id: 'a', order: 0),
      _todo(id: 'b', order: 1),
      _todo(id: 'completed', order: 0).complete(DateTime.utc(2026, 6, 2, 1)),
      _todo(id: 'other-date', date: '2026-06-03', order: 0),
    ]);
    final LocalCalendarDate date = LocalCalendarDate.parse('2026-06-02');

    expect(
      () => collection.reorder(
        date: date,
        group: CompletionGroup.incomplete,
        orderedIds: <TodoId>[TodoId.parse('a')],
        updatedAt: DateTime.utc(2026, 6, 2, 2),
      ),
      throwsA(isA<InvalidTodoReorderFailure>()),
    );
    expect(
      () => collection.reorder(
        date: date,
        group: CompletionGroup.incomplete,
        orderedIds: <TodoId>[TodoId.parse('a'), TodoId.parse('a')],
        updatedAt: DateTime.utc(2026, 6, 2, 2),
      ),
      throwsA(
        isA<InvalidTodoReorderFailure>().having(
          (InvalidTodoReorderFailure failure) => failure.reason,
          'reason',
          TodoReorderFailureReason.duplicateIdentifier,
        ),
      ),
    );
    expect(
      () => collection.reorder(
        date: date,
        group: CompletionGroup.incomplete,
        orderedIds: <TodoId>[TodoId.parse('a'), TodoId.parse('completed')],
        updatedAt: DateTime.utc(2026, 6, 2, 2),
      ),
      throwsA(isA<InvalidTodoReorderFailure>()),
    );
    expect(
      () => collection.reorder(
        date: date,
        group: CompletionGroup.incomplete,
        orderedIds: <TodoId>[TodoId.parse('a'), TodoId.parse('other-date')],
        updatedAt: DateTime.utc(2026, 6, 2, 2),
      ),
      throwsA(isA<InvalidTodoReorderFailure>()),
    );
  });

  test(
    'date movement preserves completion and appends to its target group',
    () {
      final Todo moving = _todo(
        id: 'moving',
        order: 0,
      ).complete(DateTime.utc(2026, 6, 2, 1));
      final Todo targetCompleted = _todo(
        id: 'target-completed',
        date: '2026-06-03',
        order: 6,
      ).complete(DateTime.utc(2026, 6, 2, 1));
      final Todo targetIncomplete = _todo(
        id: 'target-incomplete',
        date: '2026-06-03',
        order: 40,
      );
      final TodoCollection collection = TodoCollection.from(<Todo>[
        moving,
        targetCompleted,
        targetIncomplete,
      ]);

      final TodoCollection moved = collection.reschedule(
        id: TodoId.parse('moving'),
        date: LocalCalendarDate.parse('2026-06-03'),
        time: TodoTime.parse('11:15'),
        updatedAt: DateTime.utc(2026, 6, 2, 2),
      );
      final Todo result = moved.todoById(TodoId.parse('moving'));

      expect(result.completionGroup, CompletionGroup.completed);
      expect(result.displayOrder, 7);
      expect(result.time?.text, '11:15');
    },
  );

  test('same-date reschedule preserves display order', () {
    final TodoCollection collection = TodoCollection.from(<Todo>[
      _todo(id: 'moving', order: 11),
    ]);

    final TodoCollection rescheduled = collection.reschedule(
      id: TodoId.parse('moving'),
      date: LocalCalendarDate.parse('2026-06-02'),
      time: TodoTime.parse('19:30'),
      updatedAt: DateTime.utc(2026, 6, 2, 2),
    );

    expect(rescheduled.todoById(TodoId.parse('moving')).displayOrder, 11);
  });

  test('permanently deletes a Todo without returning an undo token', () {
    final TodoCollection collection = TodoCollection.from(<Todo>[
      _todo(id: 'delete-me'),
    ]);

    final TodoCollection deleted = collection.delete(TodoId.parse('delete-me'));

    expect(deleted.todos, isEmpty);
  });

  test('summarizes a Gregorian month without exposing Todo titles', () {
    final TodoCollection collection = TodoCollection.from(<Todo>[
      _todo(id: 'a'),
      _todo(id: 'b').complete(DateTime.utc(2026, 6, 2, 1)),
      _todo(id: 'c', date: '2026-06-03'),
      _todo(id: 'outside', date: '2026-07-01'),
    ]);

    final Map<String, TodoDaySummary> summary = collection.summaryForMonth(
      '2026-06',
    );

    expect(summary.keys, <String>['2026-06-02', '2026-06-03']);
    expect(summary['2026-06-02'], const TodoDaySummary(total: 2, completed: 1));
    expect(summary['2026-06-03'], const TodoDaySummary(total: 1, completed: 0));
    expect(() => collection.summaryForMonth('2026-6'), throwsArgumentError);
  });

  test('rejects duplicate identifiers and a 25,001st installation Todo', () {
    expect(
      () => TodoCollection.from(<Todo>[_todo(id: 'same'), _todo(id: 'same')]),
      throwsA(isA<TodoIdConflictFailure>()),
    );

    final List<Todo> fullInstallation = List<Todo>.generate(
      TodoCollection.maximumTodos,
      (int index) => _todo(id: 'todo-$index'),
      growable: false,
    );
    final TodoCollection collection = TodoCollection.from(fullInstallation);

    expect(collection.isAtCapacity, isTrue);
    expect(collection.ensureCanCreate, throwsA(isA<TodoLimitReachedFailure>()));
    expect(
      () => TodoCollection.from(<Todo>[
        ...fullInstallation,
        _todo(id: 'todo-over-limit'),
      ]),
      throwsA(isA<TodoLimitReachedFailure>()),
    );
  });

  test('compacts a group before appending past the maximum display order', () {
    final Todo maximum = _todo(
      id: 'maximum',
      date: '2026-06-03',
      order: Todo.maximumDisplayOrder,
    );
    final TodoCollection collection = TodoCollection.from(<Todo>[maximum]);

    final TodoCollection updated = collection.createTodo(
      id: TodoId.parse('appended'),
      title: TodoTitle.parse('Appended'),
      date: LocalCalendarDate.parse('2026-06-03'),
      time: null,
      createdAt: DateTime.utc(2026, 6, 3),
    );

    expect(
      updated
          .orderedForDate(LocalCalendarDate.parse('2026-06-03'))
          .map((Todo todo) => todo.displayOrder),
      <int>[0, 1],
    );
  });
}

Todo _todo({
  required String id,
  String date = '2026-06-02',
  String? time,
  int order = 0,
  DateTime? createdAt,
}) {
  return Todo.create(
    id: TodoId.parse(id),
    title: TodoTitle.parse('title-$id'),
    date: LocalCalendarDate.parse(date),
    time: TodoTime.optional(time),
    displayOrder: order,
    createdAt: createdAt ?? DateTime.utc(2026, 6, 2),
  );
}
