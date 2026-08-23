import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/create_todo.dart';
import '../application/reorder_todos.dart';
import '../application/update_todo.dart';
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

final class TodoViewState {
  TodoViewState({
    required this.todayDate,
    required this.selectedDate,
    required this.visibleMonth,
    required Iterable<TodoSnapshot> todayTodos,
    required Iterable<TodoSnapshot> selectedDateTodos,
    required Map<String, TodoDaySummary> monthSummary,
    this.isMutating = false,
    this.message,
    this.messageSerial = 0,
  }) : todayTodos = List<TodoSnapshot>.unmodifiable(todayTodos),
       selectedDateTodos = List<TodoSnapshot>.unmodifiable(selectedDateTodos),
       monthSummary = Map<String, TodoDaySummary>.unmodifiable(monthSummary) {
    if (visibleMonth.day != 1) {
      throw ArgumentError.value(
        visibleMonth,
        'visibleMonth',
        'must identify the first day of a month',
      );
    }
  }

  final LocalCalendarDate todayDate;
  final LocalCalendarDate selectedDate;
  final LocalCalendarDate visibleMonth;
  final List<TodoSnapshot> todayTodos;
  final List<TodoSnapshot> selectedDateTodos;
  final Map<String, TodoDaySummary> monthSummary;
  final bool isMutating;
  final TodoUiMessage? message;
  final int messageSerial;

  TodoViewState copyWith({
    LocalCalendarDate? todayDate,
    LocalCalendarDate? selectedDate,
    LocalCalendarDate? visibleMonth,
    Iterable<TodoSnapshot>? todayTodos,
    Iterable<TodoSnapshot>? selectedDateTodos,
    Map<String, TodoDaySummary>? monthSummary,
    bool? isMutating,
  }) {
    return TodoViewState(
      todayDate: todayDate ?? this.todayDate,
      selectedDate: selectedDate ?? this.selectedDate,
      visibleMonth: visibleMonth ?? this.visibleMonth,
      todayTodos: todayTodos ?? this.todayTodos,
      selectedDateTodos: selectedDateTodos ?? this.selectedDateTodos,
      monthSummary: monthSummary ?? this.monthSummary,
      isMutating: isMutating ?? this.isMutating,
      message: message,
      messageSerial: messageSerial,
    );
  }

  TodoViewState withoutMessage() {
    return TodoViewState(
      todayDate: todayDate,
      selectedDate: selectedDate,
      visibleMonth: visibleMonth,
      todayTodos: todayTodos,
      selectedDateTodos: selectedDateTodos,
      monthSummary: monthSummary,
      isMutating: isMutating,
      messageSerial: messageSerial,
    );
  }

  TodoViewState withMessage(TodoUiMessage nextMessage) {
    return TodoViewState(
      todayDate: todayDate,
      selectedDate: selectedDate,
      visibleMonth: visibleMonth,
      todayTodos: todayTodos,
      selectedDateTodos: selectedDateTodos,
      monthSummary: monthSummary,
      isMutating: false,
      message: nextMessage,
      messageSerial: messageSerial + 1,
    );
  }

  List<TodoSnapshot> todosForDate(LocalCalendarDate date) {
    if (date == todayDate) {
      return todayTodos;
    }
    if (date == selectedDate) {
      return selectedDateTodos;
    }
    return const <TodoSnapshot>[];
  }
}

final class TodoViewModel extends AsyncNotifier<TodoViewState> {
  late TodoPresentationDependencies _dependencies;
  late TodoDateClock _dateClock;
  int _selectionRevision = 0;
  int _monthRevision = 0;
  bool _isReconcilingDate = false;
  StreamSubscription<DateTime>? _dateChangeSubscription;

  @override
  Future<TodoViewState> build() async {
    _dependencies = ref.watch(todoPresentationDependenciesProvider);
    _dateClock = ref.watch(todoDateClockProvider);
    final StreamSubscription<DateTime>? previousSubscription =
        _dateChangeSubscription;
    if (previousSubscription != null) {
      await previousSubscription.cancel();
    }
    _dateChangeSubscription = _dateClock.localDateChanges.listen((
      DateTime changedAt,
    ) {
      unawaited(reconcileLocalDate(changedAt));
    });
    ref.onDispose(() {
      final StreamSubscription<DateTime>? subscription =
          _dateChangeSubscription;
      _dateChangeSubscription = null;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    });

    final LocalCalendarDate today = TodoDateMath.fromLocalDateTime(
      _dateClock.now(),
    );
    return _loadState(
      todayDate: today,
      selectedDate: today,
      visibleMonth: TodoDateMath.firstOfMonth(today),
    );
  }

  Future<bool> createTodo({
    required String title,
    required LocalCalendarDate date,
    required String? time,
  }) {
    return _runMutation((TodoViewState current) async {
      await _dependencies.createTodo.execute(
        CreateTodoCommand(title: title, date: date.text, time: time),
      );
      return TodoUiMessage.added;
    });
  }

  Future<bool> updateTodo({
    required TodoSnapshot todo,
    required String title,
    required LocalCalendarDate date,
    required String? time,
  }) {
    return _runMutation((TodoViewState current) async {
      await _dependencies.updateTodo.execute(
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
    return _runMutation((TodoViewState current) async {
      await _dependencies.toggleTodoCompletion.execute(todo.id);
      return todo.completed ? TodoUiMessage.reopened : TodoUiMessage.completed;
    });
  }

  Future<bool> deleteTodo(TodoSnapshot todo) {
    return _runMutation((TodoViewState current) async {
      await _dependencies.deleteTodo.execute(todo.id);
      return TodoUiMessage.deleted;
    });
  }

  Future<bool> reorderTodoGroup({
    required LocalCalendarDate date,
    required CompletionGroup group,
    required List<String> orderedIds,
  }) {
    return _runMutation((TodoViewState current) async {
      await _dependencies.reorderTodos.execute(
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

  Future<void> selectDate(LocalCalendarDate date) async {
    final TodoViewState? current = state.value;
    if (current == null || current.isMutating || current.selectedDate == date) {
      return;
    }
    final int revision = ++_selectionRevision;
    state = AsyncData<TodoViewState>(
      current.copyWith(
        selectedDate: date,
        selectedDateTodos: const <TodoSnapshot>[],
      ),
    );
    try {
      final List<TodoSnapshot> todos = await _dependencies.listTodosForDate
          .execute(date.text);
      if (revision != _selectionRevision) {
        return;
      }
      final TodoViewState? latest = state.value;
      if (latest == null || latest.selectedDate != date) {
        return;
      }
      state = AsyncData<TodoViewState>(
        latest.copyWith(selectedDateTodos: todos),
      );
    } on Object {
      if (revision == _selectionRevision) {
        _reportFailure();
      }
    }
  }

  Future<void> synchronizeSelectedDate(LocalCalendarDate date) async {
    final TodoViewState? current = state.value;
    if (current == null || current.isMutating) {
      return;
    }
    final LocalCalendarDate month = TodoDateMath.firstOfMonth(date);
    if (current.selectedDate == date && current.visibleMonth == month) {
      return;
    }
    final int selectionRevision = ++_selectionRevision;
    final int monthRevision = ++_monthRevision;
    state = AsyncData<TodoViewState>(
      current.copyWith(
        selectedDate: date,
        visibleMonth: month,
        selectedDateTodos: const <TodoSnapshot>[],
        monthSummary: const <String, TodoDaySummary>{},
      ),
    );
    try {
      final (List<TodoSnapshot>, Map<String, TodoDaySummary>) result = await (
        _dependencies.listTodosForDate.execute(date.text),
        _dependencies.listMonthSummary.execute(month.monthKey),
      ).wait;
      if (selectionRevision != _selectionRevision ||
          monthRevision != _monthRevision) {
        return;
      }
      final TodoViewState? latest = state.value;
      if (latest == null ||
          latest.selectedDate != date ||
          latest.visibleMonth != month) {
        return;
      }
      state = AsyncData<TodoViewState>(
        latest.copyWith(selectedDateTodos: result.$1, monthSummary: result.$2),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncError<TodoViewState>(error, stackTrace);
    }
  }

  Future<void> moveVisibleMonth(int offset) async {
    final TodoViewState? current = state.value;
    if (current == null || current.isMutating) {
      return;
    }
    final LocalCalendarDate? target = TodoDateMath.addMonths(
      current.visibleMonth,
      offset,
    );
    if (target == null || target == current.visibleMonth) {
      return;
    }
    await _loadVisibleMonth(target);
  }

  Future<void> goToToday() async {
    final TodoViewState? current = state.value;
    if (current == null || current.isMutating) {
      return;
    }
    await synchronizeSelectedDate(current.todayDate);
  }

  Future<void> refresh() async {
    final TodoViewState? current = state.value;
    if (current == null || current.isMutating) {
      return;
    }
    try {
      final TodoViewState refreshed = await _loadState(
        todayDate: current.todayDate,
        selectedDate: current.selectedDate,
        visibleMonth: current.visibleMonth,
        messageSerial: current.messageSerial,
      );
      state = AsyncData<TodoViewState>(refreshed);
    } on Object catch (error, stackTrace) {
      state = AsyncError<TodoViewState>(error, stackTrace);
    }
  }

  Future<void> reconcileLocalDate([DateTime? changedAt]) async {
    final TodoViewState? current = state.value;
    if (current == null || current.isMutating || _isReconcilingDate) {
      return;
    }
    final LocalCalendarDate nextToday = TodoDateMath.fromLocalDateTime(
      changedAt ?? _dateClock.now(),
    );
    if (nextToday == current.todayDate) {
      return;
    }
    _isReconcilingDate = true;
    try {
      final TodoViewState reconciled = _reconcileDates(current, nextToday);
      state = AsyncData<TodoViewState>(
        await _loadState(
          todayDate: reconciled.todayDate,
          selectedDate: reconciled.selectedDate,
          visibleMonth: reconciled.visibleMonth,
          messageSerial: current.messageSerial,
        ),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncError<TodoViewState>(error, stackTrace);
    } finally {
      _isReconcilingDate = false;
    }
  }

  Future<bool> _moveTodo(TodoSnapshot todo, int offset) async {
    final TodoViewState? current = state.value;
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

  Future<void> _loadVisibleMonth(LocalCalendarDate month) async {
    final TodoViewState? current = state.value;
    if (current == null) {
      return;
    }
    final int revision = ++_monthRevision;
    state = AsyncData<TodoViewState>(
      current.copyWith(
        visibleMonth: month,
        monthSummary: const <String, TodoDaySummary>{},
      ),
    );
    try {
      final Map<String, TodoDaySummary> summary = await _dependencies
          .listMonthSummary
          .execute(month.monthKey);
      if (revision != _monthRevision) {
        return;
      }
      final TodoViewState? latest = state.value;
      if (latest == null || latest.visibleMonth != month) {
        return;
      }
      state = AsyncData<TodoViewState>(latest.copyWith(monthSummary: summary));
    } on Object {
      if (revision == _monthRevision) {
        _reportFailure();
      }
    }
  }

  Future<bool> _runMutation(
    Future<TodoUiMessage> Function(TodoViewState current) command,
  ) async {
    final TodoViewState? current = state.value;
    if (current == null || current.isMutating) {
      return false;
    }
    state = AsyncData<TodoViewState>(
      current.withoutMessage().copyWith(isMutating: true),
    );
    try {
      final TodoUiMessage message = await command(current);
      try {
        final TodoViewState latest = state.value ?? current;
        final LocalCalendarDate actualToday = TodoDateMath.fromLocalDateTime(
          _dateClock.now(),
        );
        final TodoViewState reconciled = _reconcileDates(latest, actualToday);
        final TodoViewState refreshed = await _loadState(
          todayDate: reconciled.todayDate,
          selectedDate: reconciled.selectedDate,
          visibleMonth: reconciled.visibleMonth,
          messageSerial: latest.messageSerial,
        );
        state = AsyncData<TodoViewState>(refreshed.withMessage(message));
      } on Object catch (error, stackTrace) {
        state = AsyncError<TodoViewState>(error, stackTrace);
      }
      return true;
    } on TodoLimitReachedFailure {
      final TodoViewState latest = state.value ?? current;
      state = AsyncData<TodoViewState>(
        latest
            .copyWith(isMutating: false)
            .withMessage(TodoUiMessage.limitReached),
      );
      return false;
    } on Object {
      final TodoViewState latest = state.value ?? current;
      state = AsyncData<TodoViewState>(
        latest
            .copyWith(isMutating: false)
            .withMessage(TodoUiMessage.actionFailed),
      );
      return false;
    }
  }

  Future<TodoViewState> _loadState({
    required LocalCalendarDate todayDate,
    required LocalCalendarDate selectedDate,
    required LocalCalendarDate visibleMonth,
    int messageSerial = 0,
  }) async {
    final Future<List<TodoSnapshot>> todayRequest = _dependencies
        .listTodosForDate
        .execute(todayDate.text);
    final Future<List<TodoSnapshot>> selectedRequest = selectedDate == todayDate
        ? todayRequest
        : _dependencies.listTodosForDate.execute(selectedDate.text);
    final (List<TodoSnapshot>, List<TodoSnapshot>, Map<String, TodoDaySummary>)
    result = await (
      todayRequest,
      selectedRequest,
      _dependencies.listMonthSummary.execute(visibleMonth.monthKey),
    ).wait;
    return TodoViewState(
      todayDate: todayDate,
      selectedDate: selectedDate,
      visibleMonth: visibleMonth,
      todayTodos: result.$1,
      selectedDateTodos: result.$2,
      monthSummary: result.$3,
      messageSerial: messageSerial,
    );
  }

  TodoViewState _reconcileDates(
    TodoViewState current,
    LocalCalendarDate nextToday,
  ) {
    if (current.todayDate == nextToday) {
      return current;
    }
    final bool selectedFollowedToday =
        current.selectedDate == current.todayDate;
    final bool monthFollowedToday =
        selectedFollowedToday &&
        current.visibleMonth.monthKey == current.todayDate.monthKey;
    return current.copyWith(
      todayDate: nextToday,
      selectedDate: selectedFollowedToday ? nextToday : current.selectedDate,
      visibleMonth: monthFollowedToday
          ? TodoDateMath.firstOfMonth(nextToday)
          : current.visibleMonth,
    );
  }

  void _reportFailure() {
    final TodoViewState? current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData<TodoViewState>(
      current
          .copyWith(isMutating: false)
          .withMessage(TodoUiMessage.actionFailed),
    );
  }
}
