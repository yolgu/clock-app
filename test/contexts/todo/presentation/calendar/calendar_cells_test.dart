import 'package:clock_rhythm/contexts/todo/domain/local_calendar_date.dart';
import 'package:clock_rhythm/contexts/todo/presentation/calendar/calendar_cells.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a Sunday-first fixed 42-cell month with blank adjacency', () {
    final List<CalendarCell> cells = CalendarCells.forMonth(
      LocalCalendarDate.parse('2026-06-01'),
    );

    expect(cells, hasLength(CalendarCells.fixedCellCount));
    expect(cells.first.isCurrentMonth, isFalse);
    expect(cells[1].date?.text, '2026-06-01');
    expect(cells[30].date?.text, '2026-06-30');
    expect(cells[31].isCurrentMonth, isFalse);
    expect(cells.last.isCurrentMonth, isFalse);
  });

  test('uses Gregorian leap-day rules without adjacent month dates', () {
    final List<CalendarCell> leapCells = CalendarCells.forMonth(
      LocalCalendarDate.parse('2028-02-01'),
    );
    final List<CalendarCell> commonCells = CalendarCells.forMonth(
      LocalCalendarDate.parse('2026-02-01'),
    );

    expect(
      leapCells.where((CalendarCell cell) => cell.isCurrentMonth),
      hasLength(29),
    );
    expect(
      commonCells.where((CalendarCell cell) => cell.isCurrentMonth),
      hasLength(28),
    );
    expect(
      leapCells
          .where((CalendarCell cell) => !cell.isCurrentMonth)
          .every((CalendarCell cell) => cell.date == null && cell.day == null),
      isTrue,
    );
  });
}
