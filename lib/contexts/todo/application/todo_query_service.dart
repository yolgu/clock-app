import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import 'ports/todo_repository.dart';

final class TodoQueryService {
  const TodoQueryService({required TodoRepository repository})
    : this._(repository);

  const TodoQueryService._(this._repository);

  final TodoRepository _repository;

  Future<TodoCollection> loadCollection() async =>
      TodoCollection.from(await _repository.getAll());

  Future<List<TodoSnapshot>> listForDate(String rawDate) async {
    final LocalCalendarDate date = LocalCalendarDate.parse(rawDate);
    final TodoCollection collection = TodoCollection.from(
      await _repository.getAll(),
    );
    return List<TodoSnapshot>.unmodifiable(
      collection.orderedForDate(date).map((Todo todo) => todo.snapshot()),
    );
  }

  Future<Map<String, TodoDaySummary>> listMonthSummary(
    String rawMonthKey,
  ) async {
    final String monthKey = LocalCalendarDate.parse('$rawMonthKey-01').monthKey;
    final TodoCollection collection = TodoCollection.from(
      await _repository.getAll(),
    );
    return collection.summaryForMonth(monthKey);
  }

  Future<List<TodoSnapshot>> exportSnapshots() async {
    final TodoCollection collection = TodoCollection.from(
      await _repository.getAll(),
    );
    return List<TodoSnapshot>.unmodifiable(
      collection.todos.map((Todo todo) => todo.snapshot()),
    );
  }
}
