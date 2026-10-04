import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/todo_commands.dart';
import '../domain/completion_group.dart';
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import '../domain/todo_failure.dart';
import 'todo_date_math.dart';
import 'todo_dependencies.dart';

enum TodoUiMessage {
  added,
  updated,
  completed,
  reopened,
  deleted,
  limitReached,
  actionFailed,
}

final class TodoDataState {
  TodoDataState({
    required this.todayDate,
    required this.collection,
    this.isMutating = false,
    this.message,
    this.messageSerial = 0,
  }) : todayTodos = List<TodoSnapshot>.unmodifiable(
         collection
             .orderedForDate(todayDate)
             .map((Todo todo) => todo.snapshot()),
       );

  final LocalCalendarDate todayDate;
  final TodoCollection collection;
  final bool isMutating;
  final TodoUiMessage? message;
  final int messageSerial;

  final List<TodoSnapshot> todayTodos;

  List<TodoSnapshot> todosForDate(LocalCalendarDate date) =>
      List<TodoSnapshot>.unmodifiable(
        collection.orderedForDate(date).map((Todo todo) => todo.snapshot()),
      );

  TodoDataState copyWith({
    LocalCalendarDate? todayDate,
    TodoCollection? collection,
    bool? isMutating,
  }) => TodoDataState(
    todayDate: todayDate ?? this.todayDate,
    collection: collection ?? this.collection,
    isMutating: isMutating ?? this.isMutating,
    message: message,
    messageSerial: messageSerial,
  );

  TodoDataState withoutMessage() => TodoDataState(
    todayDate: todayDate,
    collection: collection,
    isMutating: isMutating,
    messageSerial: messageSerial,
  );

  TodoDataState withMessage(TodoUiMessage value) => TodoDataState(
    todayDate: todayDate,
    collection: collection,
    message: value,
    messageSerial: messageSerial + 1,
  );
}

final AsyncNotifierProvider<TodoDataController, TodoDataState>
todoDataControllerProvider =
    AsyncNotifierProvider<TodoDataController, TodoDataState>(
      TodoDataController.new,
    );

final class TodoDataController extends AsyncNotifier<TodoDataState> {
  late TodoPresentationDependencies _dependencies;
  late TodoDateClock _dateClock;
  StreamSubscription<DateTime>? _dateSubscription;
  bool _isReconcilingDate = false;

  @override
  Future<TodoDataState> build() async {
    _dependencies = ref.watch(todoPresentationDependenciesProvider);
    _dateClock = ref.watch(todoDateClockProvider);
    final StreamSubscription<DateTime>? previousSubscription =
        _dateSubscription;
    if (previousSubscription != null) {
      await previousSubscription.cancel();
    }
    _dateSubscription = _dateClock.localDateChanges.listen((
      DateTime changedAt,
    ) {
      unawaited(reconcileLocalDate(changedAt));
    });
    ref.onDispose(() {
      final StreamSubscription<DateTime>? subscription = _dateSubscription;
      _dateSubscription = null;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    });
    return TodoDataState(
      todayDate: TodoDateMath.fromLocalDateTime(_dateClock.now()),
      collection: await _dependencies.queries.loadCollection(),
    );
  }

  Future<bool> createTodo({
    required String title,
    required LocalCalendarDate date,
    required String? time,
  }) {
    return _runMutation(() async {
      await _dependencies.commands.create(
        CreateTodoCommand(title: title, date: date.text, time: time),
      );
      return TodoUiMessage.added;
    });
  }

  Future<bool> renameTodo({required String id, required String title}) {
    return _runMutation(() async {
      await _dependencies.commands.rename(
        RenameTodoCommand(id: id, title: title),
      );
      return TodoUiMessage.updated;
    });
  }

  Future<bool> updateTodo({
    required TodoSnapshot todo,
    required String title,
    required LocalCalendarDate date,
    required String? time,
  }) {
    return _runMutation(() async {
      await _dependencies.commands.update(
        UpdateTodoCommand(
          id: todo.id,
          title: title,
          date: date.text,
          time: time,
        ),
      );
      return TodoUiMessage.updated;
    });
  }

  Future<bool> toggleTodo(TodoSnapshot todo) {
    return _runMutation(() async {
      await _dependencies.commands.toggleCompletion(todo.id);
      return todo.completed ? TodoUiMessage.reopened : TodoUiMessage.completed;
    });
  }

  Future<bool> deleteTodo(TodoSnapshot todo) {
    return _runMutation(() async {
      await _dependencies.commands.delete(todo.id);
      return TodoUiMessage.deleted;
    });
  }

  Future<bool> reorderTodoGroup({
    required LocalCalendarDate date,
    required CompletionGroup group,
    required List<String> orderedIds,
  }) {
    return _runMutation(() async {
      await _dependencies.commands.reorder(
        ReorderTodosCommand(
          date: date.text,
          group: group,
          orderedIds: orderedIds,
        ),
      );
      return TodoUiMessage.updated;
    });
  }

  Future<bool> moveTodoUp(TodoSnapshot todo) {
    return _moveTodo(todo, -1);
  }

  Future<bool> moveTodoDown(TodoSnapshot todo) {
    return _moveTodo(todo, 1);
  }

  Future<void> refresh() async {
    final TodoDataState? current = state.value;
    if (current == null || current.isMutating) {
      return;
    }
    try {
      final TodoCollection collection = await _dependencies.queries
          .loadCollection();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<TodoDataState>(
        (state.value ?? current).copyWith(collection: collection),
      );
    } on Object catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<TodoDataState>(error, stackTrace);
      }
    }
  }

  Future<void> reconcileLocalDate([DateTime? changedAt]) async {
    final TodoDataState? current = state.value;
    if (current == null || current.isMutating || _isReconcilingDate) {
      return;
    }
    final LocalCalendarDate today = TodoDateMath.fromLocalDateTime(
      changedAt ?? _dateClock.now(),
    );
    if (today == current.todayDate) {
      return;
    }
    _isReconcilingDate = true;
    try {
      final TodoCollection collection = await _dependencies.queries
          .loadCollection();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<TodoDataState>(
        (state.value ?? current).copyWith(
          todayDate: today,
          collection: collection,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<TodoDataState>(error, stackTrace);
      }
    } finally {
      _isReconcilingDate = false;
    }
  }

  Future<bool> _moveTodo(TodoSnapshot todo, int offset) async {
    final TodoDataState? current = state.value;
    if (current == null || current.isMutating) {
      return false;
    }
    final LocalCalendarDate date = LocalCalendarDate.parse(todo.date);
    final CompletionGroup group = CompletionGroup.fromCompleted(todo.completed);
    final List<String> groupIds = current
        .todosForDate(date)
        .where(
          (TodoSnapshot candidate) => candidate.completed == todo.completed,
        )
        .map((TodoSnapshot candidate) => candidate.id)
        .toList(growable: true);
    final int currentIndex = groupIds.indexOf(todo.id);
    final int targetIndex = currentIndex + offset;
    if (currentIndex < 0 || targetIndex < 0 || targetIndex >= groupIds.length) {
      return false;
    }
    final String movedId = groupIds.removeAt(currentIndex);
    groupIds.insert(targetIndex, movedId);
    return reorderTodoGroup(date: date, group: group, orderedIds: groupIds);
  }

  Future<bool> _runMutation(Future<TodoUiMessage> Function() command) async {
    final TodoDataState? current = state.value;
    if (current == null || current.isMutating) {
      return false;
    }
    state = AsyncData<TodoDataState>(
      current.withoutMessage().copyWith(isMutating: true),
    );
    try {
      final TodoUiMessage message = await command();
      try {
        final LocalCalendarDate today = TodoDateMath.fromLocalDateTime(
          _dateClock.now(),
        );
        final TodoCollection collection = await _dependencies.queries
            .loadCollection();
        if (!ref.mounted) {
          return true;
        }
        state = AsyncData<TodoDataState>(
          current
              .copyWith(todayDate: today, collection: collection)
              .withMessage(message),
        );
      } on Object catch (error, stackTrace) {
        if (ref.mounted) {
          state = AsyncError<TodoDataState>(error, stackTrace);
        }
      }
      return true;
    } on TodoLimitReachedFailure {
      if (ref.mounted) {
        state = AsyncData<TodoDataState>(
          current.withMessage(TodoUiMessage.limitReached),
        );
      }
      return false;
    } on Object {
      if (ref.mounted) {
        state = AsyncData<TodoDataState>(
          current.withMessage(TodoUiMessage.actionFailed),
        );
      }
      return false;
    }
  }
}
