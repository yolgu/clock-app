import 'package:clock_rhythm/contexts/todo/domain/completion_group.dart';
import 'package:clock_rhythm/contexts/todo/domain/local_calendar_date.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_id.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_time.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates an incomplete immutable Todo with stable timestamps', () {
    final Todo todo = _todo();
    final TodoSnapshot snapshot = todo.snapshot();

    expect(snapshot.id, 'todo-1');
    expect(snapshot.title, '과제 정리');
    expect(snapshot.date, '2026-06-02');
    expect(snapshot.time, isNull);
    expect(snapshot.completed, isFalse);
    expect(snapshot.displayOrder, 3);
    expect(snapshot.createdAt, '2026-06-02T00:00:00.000Z');
    expect(snapshot.updatedAt, snapshot.createdAt);
  });

  test('completion and reopening preserve display order', () {
    final Todo original = _todo();
    final Todo completed = original.complete(DateTime.utc(2026, 6, 2, 1));
    final Todo reopened = completed.reopen(DateTime.utc(2026, 6, 2, 2));

    expect(original.completionGroup, CompletionGroup.incomplete);
    expect(completed.completionGroup, CompletionGroup.completed);
    expect(reopened.completionGroup, CompletionGroup.incomplete);
    expect(completed.displayOrder, original.displayOrder);
    expect(reopened.displayOrder, original.displayOrder);
    expect(original.updatedAt, DateTime.utc(2026, 6, 2));
    expect(reopened.updatedAt, DateTime.utc(2026, 6, 2, 2));
  });

  test('rename and reschedule preserve unrelated Todo state', () {
    final Todo original = _todo().complete(DateTime.utc(2026, 6, 2, 1));
    final Todo renamed = original.rename(
      TodoTitle.parse('새 이름'),
      DateTime.utc(2026, 6, 2, 2),
    );
    final Todo moved = renamed.reschedule(
      date: LocalCalendarDate.parse('2026-06-03'),
      time: TodoTime.parse('07:30'),
      displayOrder: 8,
      updatedAt: DateTime.utc(2026, 6, 2, 3),
    );

    expect(moved.id, original.id);
    expect(moved.title.text, '새 이름');
    expect(moved.date.text, '2026-06-03');
    expect(moved.time?.text, '07:30');
    expect(moved.completionGroup, CompletionGroup.completed);
    expect(moved.displayOrder, 8);
    expect(moved.createdAt, original.createdAt);
  });

  test('restores and canonicalizes a validated timestamp fixture', () {
    final Todo restored = Todo.restore(
      const TodoRestoreSnapshot(
        id: 'legacy-1',
        title: '가져온 할 일',
        date: '2028-02-29',
        time: '14:30',
        completed: true,
        displayOrder: 12,
        createdAt: '2026-08-22T09:00:00+09:00',
        updatedAt: '2026-08-22T01:00:00.000Z',
      ),
    );

    expect(restored.snapshot().createdAt, '2026-08-22T00:00:00.000Z');
    expect(restored.snapshot().updatedAt, '2026-08-22T01:00:00.000Z');
    expect(restored.snapshot().displayOrder, 12);
  });

  test('derives a missing legacy display order from creation milliseconds', () {
    final Todo restored = Todo.restore(
      const TodoRestoreSnapshot(
        id: 'legacy-1',
        title: '기존 할 일',
        date: '2026-06-02',
        time: null,
        completed: false,
        displayOrder: null,
        createdAt: '2026-06-02T09:03:00.000Z',
        updatedAt: '2026-06-02T09:03:00.000Z',
      ),
    );

    expect(
      restored.displayOrder,
      DateTime.parse('2026-06-02T09:03:00.000Z').millisecondsSinceEpoch,
    );
  });

  test('rejects invalid restore timestamp and display-order invariants', () {
    TodoRestoreSnapshot snapshot({
      String createdAt = '2026-06-02T09:03:00.000Z',
      String updatedAt = '2026-06-02T09:03:00.000Z',
      int? displayOrder = 0,
    }) {
      return TodoRestoreSnapshot(
        id: 'legacy-1',
        title: '기존 할 일',
        date: '2026-06-02',
        time: null,
        completed: false,
        displayOrder: displayOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    expect(
      () => Todo.restore(snapshot(createdAt: 'not-an-instant')),
      throwsArgumentError,
    );
    expect(
      () => Todo.restore(snapshot(createdAt: '2026-02-30T09:03:00.000Z')),
      throwsArgumentError,
    );
    expect(
      () => Todo.restore(snapshot(createdAt: '2026-06-02T09:03:00')),
      throwsArgumentError,
    );
    expect(
      () => Todo.restore(snapshot(updatedAt: '2026-06-02T09:02:59.999Z')),
      throwsArgumentError,
    );
    expect(() => Todo.restore(snapshot(displayOrder: -1)), throwsArgumentError);
  });

  test('never moves updatedAt backwards when the wall clock is corrected', () {
    final Todo todo = _todo().rename(
      TodoTitle.parse('첫 변경'),
      DateTime.utc(2026, 6, 2, 2),
    );

    final Todo renamed = todo.rename(
      TodoTitle.parse('두 번째 변경'),
      DateTime.utc(2026, 6, 2, 1),
    );

    expect(renamed.updatedAt, DateTime.utc(2026, 6, 2, 2));
  });

  test('normalizes timestamps to Neutralino millisecond precision', () {
    final Todo created = Todo.create(
      id: TodoId.parse('milliseconds'),
      title: TodoTitle.parse('Precision'),
      date: LocalCalendarDate.parse('2026-08-23'),
      time: null,
      displayOrder: 0,
      createdAt: DateTime.utc(2026, 8, 23, 1, 2, 3, 123, 456),
    );
    final Todo restored = Todo.restore(
      const TodoRestoreSnapshot(
        id: 'restored-milliseconds',
        title: 'Precision',
        date: '2026-08-23',
        time: null,
        completed: false,
        displayOrder: 0,
        createdAt: '2026-08-23T01:02:03.123456Z',
        updatedAt: '2026-08-23T01:02:03.999999Z',
      ),
    );

    expect(created.snapshot().createdAt, '2026-08-23T01:02:03.123Z');
    expect(restored.snapshot().createdAt, '2026-08-23T01:02:03.123Z');
    expect(restored.snapshot().updatedAt, '2026-08-23T01:02:03.999Z');
  });
}

Todo _todo({
  String id = 'todo-1',
  String title = '과제 정리',
  String date = '2026-06-02',
  String? time,
  int displayOrder = 3,
  DateTime? now,
}) {
  return Todo.create(
    id: TodoId.parse(id),
    title: TodoTitle.parse(title),
    date: LocalCalendarDate.parse(date),
    time: TodoTime.optional(time),
    displayOrder: displayOrder,
    createdAt: now ?? DateTime.utc(2026, 6, 2),
  );
}
