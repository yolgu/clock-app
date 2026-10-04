import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar/calendar_view_model.dart';
import 'todo_data_controller.dart';
import 'todo_view_state.dart';

export 'calendar/calendar_view_model.dart'
    show CalendarViewModel, calendarViewModelProvider;
export 'todo_data_controller.dart'
    show
        TodoDataController,
        TodoDataState,
        TodoUiMessage,
        todoDataControllerProvider;

final Provider<AsyncValue<TodoViewState>> todoViewStateProvider =
    Provider<AsyncValue<TodoViewState>>((Ref ref) {
      final AsyncValue<TodoDataState> data = ref.watch(
        todoDataControllerProvider,
      );
      final CalendarSelection selection = ref.watch(calendarViewModelProvider);
      return data.whenData(
        (TodoDataState value) =>
            TodoViewState(data: value, selection: selection),
      );
    }, name: 'todoViewStateProvider');
