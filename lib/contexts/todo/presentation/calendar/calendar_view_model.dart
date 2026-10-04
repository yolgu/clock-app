import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/local_calendar_date.dart';
import '../todo_data_controller.dart';
import '../todo_date_math.dart';
import '../todo_dependencies.dart';

final class CalendarSelection {
  const CalendarSelection({
    required this.selectedDate,
    required this.visibleMonth,
  });
  final LocalCalendarDate selectedDate;
  final LocalCalendarDate visibleMonth;
}

final NotifierProvider<CalendarViewModel, CalendarSelection>
calendarViewModelProvider =
    NotifierProvider<CalendarViewModel, CalendarSelection>(
      CalendarViewModel.new,
    );

final class CalendarViewModel extends Notifier<CalendarSelection> {
  @override
  CalendarSelection build() {
    final LocalCalendarDate today =
        ref.read(todoDataControllerProvider).value?.todayDate ??
        TodoDateMath.fromLocalDateTime(ref.read(todoDateClockProvider).now());
    ref.listen<LocalCalendarDate?>(
      todoDataControllerProvider.select(
        (AsyncValue<TodoDataState> value) => value.value?.todayDate,
      ),
      (LocalCalendarDate? previous, LocalCalendarDate? next) {
        if (previous == null || next == null || previous == next) {
          return;
        }
        final bool followsToday = state.selectedDate == previous;
        final bool monthFollowsToday =
            followsToday && state.visibleMonth.monthKey == previous.monthKey;
        state = CalendarSelection(
          selectedDate: followsToday ? next : state.selectedDate,
          visibleMonth: monthFollowsToday
              ? TodoDateMath.firstOfMonth(next)
              : state.visibleMonth,
        );
      },
    );
    return CalendarSelection(
      selectedDate: today,
      visibleMonth: TodoDateMath.firstOfMonth(today),
    );
  }

  bool get _canNavigate {
    final TodoDataState? data = ref.read(todoDataControllerProvider).value;
    return data != null && !data.isMutating;
  }

  Future<void> selectDate(LocalCalendarDate date) async {
    if (!_canNavigate || state.selectedDate == date) {
      return;
    }
    state = CalendarSelection(
      selectedDate: date,
      visibleMonth: state.visibleMonth,
    );
  }

  Future<void> synchronizeSelectedDate(LocalCalendarDate date) async {
    if (!_canNavigate) {
      return;
    }
    state = CalendarSelection(
      selectedDate: date,
      visibleMonth: TodoDateMath.firstOfMonth(date),
    );
  }

  Future<void> moveVisibleMonth(int offset) async {
    if (!_canNavigate) {
      return;
    }
    final LocalCalendarDate? target = TodoDateMath.addMonths(
      state.visibleMonth,
      offset,
    );
    if (target != null && target != state.visibleMonth) {
      state = CalendarSelection(
        selectedDate: state.selectedDate,
        visibleMonth: target,
      );
    }
  }

  Future<void> goToToday() async {
    final TodoDataState? data = ref.read(todoDataControllerProvider).value;
    if (data != null) {
      await synchronizeSelectedDate(data.todayDate);
    }
  }
}
