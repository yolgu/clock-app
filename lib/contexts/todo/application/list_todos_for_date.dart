import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_collection.dart';
import 'ports/todo_repository.dart';

final class ListTodosForDate {
  const ListTodosForDate({required TodoRepository repository})
    : this._(repository);

  const ListTodosForDate._(this._repository);

  final TodoRepository _repository;

  Future<List<TodoSnapshot>> execute(String rawDate) async {
    final LocalCalendarDate date = LocalCalendarDate.parse(rawDate);
    final TodoCollection collection = TodoCollection.from(
      await _repository.getAll(),
    );
    return List<TodoSnapshot>.unmodifiable(
      collection.orderedForDate(date).map((Todo todo) => todo.snapshot()),
    );
  }
}
