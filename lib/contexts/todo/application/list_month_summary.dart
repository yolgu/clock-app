import '../domain/local_calendar_date.dart';
import '../domain/todo_collection.dart';
import 'ports/todo_repository.dart';

final class ListMonthSummary {
  const ListMonthSummary({required TodoRepository repository})
    : this._(repository);

  const ListMonthSummary._(this._repository);

  final TodoRepository _repository;

  Future<Map<String, TodoDaySummary>> execute(String rawMonthKey) async {
    final String monthKey = LocalCalendarDate.parse('$rawMonthKey-01').monthKey;
    final TodoCollection collection = TodoCollection.from(
      await _repository.getAll(),
    );
    return collection.summaryForMonth(monthKey);
  }
}
