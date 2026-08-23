import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports the planned Todo presentation surface', () {
    _acceptType<TodoViewModel>();
    _acceptType<TodoViewState>();
    _acceptType<TodoUiMessage>();
    _acceptType<TodoPresentationDependencies>();
    _acceptType<TodoDateClock>();
    _acceptType<TodayTodoPanel>();
    _acceptType<TodoListPanel>();
    _acceptType<TodoEditor>();
    _acceptType<CalendarPage>();

    expect(todoViewModelProvider.name, 'todoViewModelProvider');
    expect(
      todoPresentationDependenciesProvider.name,
      'todoPresentationDependenciesProvider',
    );
    expect(todoDateClockProvider.name, 'todoDateClockProvider');
  });
}

void _acceptType<T>() {}
