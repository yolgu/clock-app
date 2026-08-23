import 'dart:collection';

import 'completion_group.dart';
import 'local_calendar_date.dart';
import 'todo.dart';
import 'todo_failure.dart';
import 'todo_id.dart';
import 'todo_time.dart';
import 'todo_title.dart';

typedef _AppendPlan = ({List<Todo> todos, int displayOrder});

final class TodoDaySummary {
  const TodoDaySummary({required this.total, required this.completed});

  final int total;
  final int completed;

  TodoDaySummary _include(CompletionGroup group) {
    return TodoDaySummary(
      total: total + 1,
      completed: completed + (group.isCompleted ? 1 : 0),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TodoDaySummary &&
            total == other.total &&
            completed == other.completed;
  }

  @override
  int get hashCode => Object.hash(total, completed);
}

final class TodoCollection {
  TodoCollection._(List<Todo> todos) : _todos = List<Todo>.unmodifiable(todos);

  static const int maximumTodos = Todo.maximumInstallationCount;

  final List<Todo> _todos;

  factory TodoCollection.from(Iterable<Todo> todos) {
    final List<Todo> ownedTodos = List<Todo>.of(todos, growable: false);
    if (ownedTodos.length > maximumTodos) {
      throw TodoLimitReachedFailure(
        actualCount: ownedTodos.length,
        maximumCount: maximumTodos,
      );
    }

    final Set<TodoId> identifiers = <TodoId>{};
    for (final Todo todo in ownedTodos) {
      if (!identifiers.add(todo.id)) {
        throw TodoIdConflictFailure(todo.id);
      }
    }
    return TodoCollection._(ownedTodos);
  }

  List<Todo> get todos => _todos;

  bool get isAtCapacity => _todos.length >= maximumTodos;

  void ensureCanCreate() {
    if (isAtCapacity) {
      throw TodoLimitReachedFailure(
        actualCount: _todos.length,
        maximumCount: maximumTodos,
      );
    }
  }

  Todo todoById(TodoId id) {
    for (final Todo todo in _todos) {
      if (todo.id == id) {
        return todo;
      }
    }
    throw TodoNotFoundFailure(id);
  }

  TodoCollection createTodo({
    required TodoId id,
    required TodoTitle title,
    required LocalCalendarDate date,
    required TodoTime? time,
    required DateTime createdAt,
  }) {
    ensureCanCreate();
    if (_todos.any((Todo todo) => todo.id == id)) {
      throw TodoIdConflictFailure(id);
    }
    final _AppendPlan appendPlan = _appendPlan(
      date,
      CompletionGroup.incomplete,
      createdAt,
    );
    final Todo todo = Todo.create(
      id: id,
      title: title,
      date: date,
      time: time,
      displayOrder: appendPlan.displayOrder,
      createdAt: createdAt,
    );
    return TodoCollection.from(<Todo>[...appendPlan.todos, todo]);
  }

  TodoCollection rename({
    required TodoId id,
    required TodoTitle title,
    required DateTime updatedAt,
  }) {
    final Todo renamed = todoById(id).rename(title, updatedAt);
    return _replace(renamed);
  }

  TodoCollection reschedule({
    required TodoId id,
    required LocalCalendarDate date,
    required TodoTime? time,
    required DateTime updatedAt,
  }) {
    final Todo target = todoById(id);
    final _AppendPlan appendPlan = target.date == date
        ? (todos: _todos, displayOrder: target.displayOrder)
        : _appendPlan(date, target.completionGroup, updatedAt);
    final Todo rescheduled = target.reschedule(
      date: date,
      time: time,
      displayOrder: appendPlan.displayOrder,
      updatedAt: updatedAt,
    );
    return _replaceIn(appendPlan.todos, rescheduled);
  }

  TodoCollection update({
    required TodoId id,
    required TodoTitle title,
    required LocalCalendarDate date,
    required TodoTime? time,
    required DateTime updatedAt,
  }) {
    final Todo target = todoById(id);
    final _AppendPlan appendPlan = target.date == date
        ? (todos: _todos, displayOrder: target.displayOrder)
        : _appendPlan(date, target.completionGroup, updatedAt);
    final Todo edited = target.edit(
      title: title,
      date: date,
      time: time,
      displayOrder: appendPlan.displayOrder,
      updatedAt: updatedAt,
    );
    return _replaceIn(appendPlan.todos, edited);
  }

  TodoCollection toggleCompletion(TodoId id, DateTime updatedAt) {
    final Todo target = todoById(id);
    final Todo toggled = switch (target.completionGroup) {
      CompletionGroup.incomplete => target.complete(updatedAt),
      CompletionGroup.completed => target.reopen(updatedAt),
    };
    return _replace(toggled);
  }

  TodoCollection reorder({
    required LocalCalendarDate date,
    required CompletionGroup group,
    required Iterable<TodoId> orderedIds,
    required DateTime updatedAt,
  }) {
    final List<TodoId> permutation = List<TodoId>.of(
      orderedIds,
      growable: false,
    );
    final Set<TodoId> permutationIds = permutation.toSet();
    if (permutationIds.length != permutation.length) {
      throw const InvalidTodoReorderFailure(
        TodoReorderFailureReason.duplicateIdentifier,
      );
    }

    final Set<TodoId> groupIds = _todos
        .where(
          (Todo todo) => todo.date == date && todo.completionGroup == group,
        )
        .map((Todo todo) => todo.id)
        .toSet();
    if (permutationIds.length != groupIds.length ||
        !permutationIds.containsAll(groupIds)) {
      throw const InvalidTodoReorderFailure(
        TodoReorderFailureReason.notFullGroupPermutation,
      );
    }

    final Map<TodoId, int> orderById = <TodoId, int>{
      for (int index = 0; index < permutation.length; index += 1)
        permutation[index]: index,
    };
    final List<Todo> reordered = _todos
        .map((Todo todo) {
          final int? displayOrder = orderById[todo.id];
          return displayOrder == null
              ? todo
              : todo.moveToDisplayOrder(displayOrder, updatedAt);
        })
        .toList(growable: false);
    return TodoCollection.from(reordered);
  }

  TodoCollection delete(TodoId id) {
    return TodoCollection.from(_todos.where((Todo todo) => todo.id != id));
  }

  List<Todo> orderedForDate(LocalCalendarDate date) {
    final List<Todo> matchingTodos =
        _todos.where((Todo todo) => todo.date == date).toList(growable: false)
          ..sort(_compareForDailyView);
    return List<Todo>.unmodifiable(matchingTodos);
  }

  Map<String, TodoDaySummary> summaryForMonth(String monthKey) {
    final String canonicalMonth = LocalCalendarDate.parse(
      '$monthKey-01',
    ).monthKey;
    final SplayTreeMap<String, TodoDaySummary> summary =
        SplayTreeMap<String, TodoDaySummary>();
    for (final Todo todo in _todos) {
      if (todo.date.monthKey != canonicalMonth) {
        continue;
      }
      final TodoDaySummary current =
          summary[todo.date.text] ??
          const TodoDaySummary(total: 0, completed: 0);
      summary[todo.date.text] = current._include(todo.completionGroup);
    }
    return Map<String, TodoDaySummary>.unmodifiable(summary);
  }

  TodoCollection _replace(Todo replacement) {
    return _replaceIn(_todos, replacement);
  }

  TodoCollection _replaceIn(List<Todo> source, Todo replacement) {
    return TodoCollection.from(
      source.map((Todo todo) => todo.id == replacement.id ? replacement : todo),
    );
  }

  _AppendPlan _appendPlan(
    LocalCalendarDate date,
    CompletionGroup group,
    DateTime changedAt,
  ) {
    int maximumOrder = -1;
    for (final Todo todo in _todos) {
      if (todo.date == date &&
          todo.completionGroup == group &&
          todo.displayOrder > maximumOrder) {
        maximumOrder = todo.displayOrder;
      }
    }
    if (maximumOrder < Todo.maximumDisplayOrder) {
      return (todos: _todos, displayOrder: maximumOrder + 1);
    }

    final List<Todo> groupTodos =
        _todos
            .where(
              (Todo todo) => todo.date == date && todo.completionGroup == group,
            )
            .toList(growable: false)
          ..sort(_compareForDailyView);
    final Map<TodoId, int> compactOrder = <TodoId, int>{
      for (int index = 0; index < groupTodos.length; index += 1)
        groupTodos[index].id: index,
    };
    final List<Todo> compacted = _todos
        .map((Todo todo) {
          final int? order = compactOrder[todo.id];
          return order == null
              ? todo
              : todo.moveToDisplayOrder(order, changedAt);
        })
        .toList(growable: false);
    return (todos: compacted, displayOrder: groupTodos.length);
  }

  static int _compareForDailyView(Todo left, Todo right) {
    final int groupComparison = left.completionGroup.sortOrder.compareTo(
      right.completionGroup.sortOrder,
    );
    if (groupComparison != 0) {
      return groupComparison;
    }
    final int orderComparison = left.displayOrder.compareTo(right.displayOrder);
    if (orderComparison != 0) {
      return orderComparison;
    }
    final int creationComparison = left.createdAt.compareTo(right.createdAt);
    if (creationComparison != 0) {
      return creationComparison;
    }
    return left.id.compareTo(right.id);
  }
}
