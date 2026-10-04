import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import 'calendar/calendar_view_model.dart';
import 'todo_data_controller.dart';

final class TodoViewState {
  TodoViewState({required this.data, required this.selection})
    : selectedDateTodos = data.todosForDate(selection.selectedDate),
      monthSummary = data.collection.summaryForMonth(
        selection.visibleMonth.monthKey,
      );
  final TodoDataState data;
  final CalendarSelection selection;

  LocalCalendarDate get todayDate => data.todayDate;
  LocalCalendarDate get selectedDate => selection.selectedDate;
  LocalCalendarDate get visibleMonth => selection.visibleMonth;
  List<TodoSnapshot> get todayTodos => data.todayTodos;
  final List<TodoSnapshot> selectedDateTodos;
  final Map<String, TodoDaySummary> monthSummary;
  bool get isMutating => data.isMutating;
  TodoUiMessage? get message => data.message;
  int get messageSerial => data.messageSerial;
  List<TodoSnapshot> todosForDate(LocalCalendarDate date) =>
      data.todosForDate(date);
}
