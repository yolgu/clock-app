import 'completion_group.dart';
import 'local_calendar_date.dart';
import 'todo_id.dart';
import 'todo_time.dart';
import 'todo_title.dart';

final class TodoSnapshot {
  const TodoSnapshot({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.completed,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String date;
  final String? time;
  final bool completed;
  final int displayOrder;
  final String createdAt;
  final String updatedAt;

  TodoRestoreSnapshot toRestoreSnapshot() {
    return TodoRestoreSnapshot(
      id: id,
      title: title,
      date: date,
      time: time,
      completed: completed,
      displayOrder: displayOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TodoSnapshot &&
            id == other.id &&
            title == other.title &&
            date == other.date &&
            time == other.time &&
            completed == other.completed &&
            displayOrder == other.displayOrder &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    time,
    completed,
    displayOrder,
    createdAt,
    updatedAt,
  );
}

final class TodoRestoreSnapshot {
  const TodoRestoreSnapshot({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.completed,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String date;
  final String? time;
  final bool completed;
  final int? displayOrder;
  final String createdAt;
  final String updatedAt;
}

final class Todo {
  const Todo._({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.completionGroup,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  static final RegExp _instantPattern = RegExp(
    r'^(?<date>\d{4}-\d{2}-\d{2})T'
    r'(?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2})'
    r'(?:\.\d{1,6})?'
    r'(?:[zZ]|[+-](?:[01]\d|2[0-3]):[0-5]\d)$',
  );
  static const int maximumInstallationCount = 25000;
  static const int maximumDisplayOrder = 0x7FFFFFFFFFFFFFFF;

  final TodoId id;
  final TodoTitle title;
  final LocalCalendarDate date;
  final TodoTime? time;
  final CompletionGroup completionGroup;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Todo.create({
    required TodoId id,
    required TodoTitle title,
    required LocalCalendarDate date,
    required TodoTime? time,
    required int displayOrder,
    required DateTime createdAt,
  }) {
    final DateTime createdInstant = _toUtcMilliseconds(createdAt);
    return Todo._(
      id: id,
      title: title,
      date: date,
      time: time,
      completionGroup: CompletionGroup.incomplete,
      displayOrder: _validateDisplayOrder(displayOrder),
      createdAt: createdInstant,
      updatedAt: createdInstant,
    );
  }

  factory Todo.restore(TodoRestoreSnapshot snapshot) {
    final DateTime createdAt = _parseInstant(snapshot.createdAt, 'createdAt');
    final DateTime updatedAt = _parseInstant(snapshot.updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        snapshot.updatedAt,
        'updatedAt',
        'Todo updatedAt must not be earlier than createdAt',
      );
    }
    final int displayOrder =
        snapshot.displayOrder ?? createdAt.millisecondsSinceEpoch;

    return Todo._(
      id: TodoId.parse(snapshot.id),
      title: TodoTitle.parse(snapshot.title),
      date: LocalCalendarDate.parse(snapshot.date),
      time: TodoTime.optional(snapshot.time),
      completionGroup: CompletionGroup.fromCompleted(snapshot.completed),
      displayOrder: _validateDisplayOrder(displayOrder),
      createdAt: _toUtcMilliseconds(createdAt),
      updatedAt: _toUtcMilliseconds(updatedAt),
    );
  }

  Todo complete(DateTime changedAt) {
    return _withCompletion(CompletionGroup.completed, changedAt);
  }

  Todo reopen(DateTime changedAt) {
    return _withCompletion(CompletionGroup.incomplete, changedAt);
  }

  Todo rename(TodoTitle title, DateTime changedAt) {
    return Todo._(
      id: id,
      title: title,
      date: date,
      time: time,
      completionGroup: completionGroup,
      displayOrder: displayOrder,
      createdAt: createdAt,
      updatedAt: _nextUpdatedAt(changedAt),
    );
  }

  Todo reschedule({
    required LocalCalendarDate date,
    required TodoTime? time,
    required int displayOrder,
    required DateTime updatedAt,
  }) {
    return Todo._(
      id: id,
      title: title,
      date: date,
      time: time,
      completionGroup: completionGroup,
      displayOrder: _validateDisplayOrder(displayOrder),
      createdAt: createdAt,
      updatedAt: _nextUpdatedAt(updatedAt),
    );
  }

  Todo edit({
    required TodoTitle title,
    required LocalCalendarDate date,
    required TodoTime? time,
    required int displayOrder,
    required DateTime updatedAt,
  }) {
    return Todo._(
      id: id,
      title: title,
      date: date,
      time: time,
      completionGroup: completionGroup,
      displayOrder: _validateDisplayOrder(displayOrder),
      createdAt: createdAt,
      updatedAt: _nextUpdatedAt(updatedAt),
    );
  }

  Todo moveToDisplayOrder(int displayOrder, DateTime changedAt) {
    return Todo._(
      id: id,
      title: title,
      date: date,
      time: time,
      completionGroup: completionGroup,
      displayOrder: _validateDisplayOrder(displayOrder),
      createdAt: createdAt,
      updatedAt: _nextUpdatedAt(changedAt),
    );
  }

  TodoSnapshot snapshot() {
    return TodoSnapshot(
      id: id.text,
      title: title.text,
      date: date.text,
      time: time?.text,
      completed: completionGroup.isCompleted,
      displayOrder: displayOrder,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt.toIso8601String(),
    );
  }

  Todo _withCompletion(CompletionGroup group, DateTime changedAt) {
    return Todo._(
      id: id,
      title: title,
      date: date,
      time: time,
      completionGroup: group,
      displayOrder: displayOrder,
      createdAt: createdAt,
      updatedAt: _nextUpdatedAt(changedAt),
    );
  }

  DateTime _nextUpdatedAt(DateTime changedAt) {
    final DateTime candidate = _toUtcMilliseconds(changedAt);
    return candidate.isBefore(updatedAt) ? updatedAt : candidate;
  }

  static int _validateDisplayOrder(int displayOrder) {
    if (displayOrder < 0 || displayOrder > maximumDisplayOrder) {
      throw ArgumentError.value(
        displayOrder,
        'displayOrder',
        'Todo display order must fit a nonnegative SQLite integer',
      );
    }
    return displayOrder;
  }

  static DateTime _parseInstant(String text, String name) {
    final RegExpMatch? match = _instantPattern.firstMatch(text);
    if (match == null) {
      throw ArgumentError.value(text, name, 'must identify an instant');
    }
    LocalCalendarDate.parse(match.namedGroup('date')!);
    final int hour = int.parse(match.namedGroup('hour')!);
    final int minute = int.parse(match.namedGroup('minute')!);
    final int second = int.parse(match.namedGroup('second')!);
    if (hour > 23 || minute > 59 || second > 59) {
      throw ArgumentError.value(text, name, 'must identify an instant');
    }
    final DateTime? parsed = DateTime.tryParse(text);
    if (parsed == null || !parsed.isUtc) {
      throw ArgumentError.value(text, name, 'must be a parseable instant');
    }
    return parsed.toUtc();
  }

  static DateTime _toUtcMilliseconds(DateTime value) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toUtc().millisecondsSinceEpoch,
      isUtc: true,
    );
  }
}
