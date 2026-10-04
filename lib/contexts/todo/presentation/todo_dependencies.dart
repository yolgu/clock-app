import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/todo_command_service.dart';
import '../application/todo_query_service.dart';

final class TodoPresentationDependencies {
  const TodoPresentationDependencies({
    required this.commands,
    required this.queries,
  });

  final TodoCommandService commands;
  final TodoQueryService queries;
}

abstract interface class TodoDateClock {
  DateTime now();

  Stream<DateTime> get localDateChanges;
}

final class SystemTodoDateClock
    with WidgetsBindingObserver
    implements TodoDateClock {
  SystemTodoDateClock({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _changes = StreamController<DateTime>.broadcast(sync: true) {
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextLocalMidnight();
  }

  final DateTime Function() _now;
  final StreamController<DateTime> _changes;
  Timer? _midnightTimer;
  bool _isDisposed = false;

  @override
  DateTime now() => _now();

  @override
  Stream<DateTime> get localDateChanges => _changes.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _isDisposed) {
      return;
    }
    _changes.add(now());
    _scheduleNextLocalMidnight();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    unawaited(_changes.close());
  }

  void _scheduleNextLocalMidnight() {
    _midnightTimer?.cancel();
    final DateTime current = now();
    final DateTime nextMidnight = DateTime(
      current.year,
      current.month,
      current.day + 1,
    );
    final Duration delay = nextMidnight.difference(current);
    _midnightTimer = Timer(delay, () {
      if (_isDisposed) {
        return;
      }
      _changes.add(now());
      _scheduleNextLocalMidnight();
    });
  }
}

final Provider<TodoPresentationDependencies>
todoPresentationDependenciesProvider = Provider<TodoPresentationDependencies>((
  Ref ref,
) {
  throw StateError(
    'TodoPresentationDependencies must be supplied by app composition.',
  );
}, name: 'todoPresentationDependenciesProvider');

final Provider<TodoDateClock> todoDateClockProvider = Provider<TodoDateClock>((
  Ref ref,
) {
  final SystemTodoDateClock clock = SystemTodoDateClock();
  ref.onDispose(clock.dispose);
  return clock;
}, name: 'todoDateClockProvider');
