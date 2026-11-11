import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
import '../../../shared/ui/public.dart'
    show ClockRhythmRadius, ClockRhythmSpace, LineGlyph, LineIcon;
import '../domain/local_calendar_date.dart';
import '../domain/todo_collection.dart';
import 'calendar/calendar_cells.dart';
import 'todo_date_math.dart';

/// The month a Todo's date is picked from, unfolded under the date field.
///
/// It reads like the app's calendar in its compact form: today's number sits
/// in an accent circle, the chosen day is tinted, and a dot marks days that
/// already hold Todos.
final class TodoDatePanel extends StatefulWidget {
  const TodoDatePanel({
    required this.selected,
    required this.today,
    required this.summaryForMonth,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final LocalCalendarDate selected;
  final LocalCalendarDate today;

  /// The Todos of each day in a month, keyed by the day's ISO date text.
  final Map<String, TodoDaySummary> Function(String monthKey) summaryForMonth;
  final ValueChanged<LocalCalendarDate> onSelected;
  final bool enabled;

  @override
  State<TodoDatePanel> createState() => _TodoDatePanelState();
}

final class _TodoDatePanelState extends State<TodoDatePanel> {
  static const double _cellSpacing = ClockRhythmSpace.space4;
  static const double _cellHeight = 48;

  late LocalCalendarDate _visibleMonth = TodoDateMath.firstOfMonth(
    widget.selected,
  );

  void _showMonth(LocalCalendarDate? month) {
    if (month == null) {
      return;
    }
    setState(() {
      _visibleMonth = month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    final LocalDateFormatter formatter = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final String monthLabel = formatter.formatMonth(
      TodoDateMath.toLocalDateTime(_visibleMonth),
    );
    final LocalCalendarDate? previousMonth = TodoDateMath.addMonths(
      _visibleMonth,
      -1,
    );
    final LocalCalendarDate? nextMonth = TodoDateMath.addMonths(
      _visibleMonth,
      1,
    );
    final List<CalendarCell> cells = _visibleRows(
      CalendarCells.forMonth(_visibleMonth),
    );
    final Map<String, TodoDaySummary> summary = widget.summaryForMonth(
      _visibleMonth.monthKey,
    );
    final List<String> weekdays = <String>[
      localizations.calendarWeekdaySunday,
      localizations.calendarWeekdayMonday,
      localizations.calendarWeekdayTuesday,
      localizations.calendarWeekdayWednesday,
      localizations.calendarWeekdayThursday,
      localizations.calendarWeekdayFriday,
      localizations.calendarWeekdaySaturday,
    ];
    final double cellHeight =
        _cellHeight +
        math.max(0, MediaQuery.textScalerOf(context).scale(1) - 1) * 32;
    return Semantics(
      container: true,
      label: localizations.todoDatePanelLabel,
      child: DecoratedBox(
        key: const ValueKey<String>('todo-date-panel'),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(ClockRhythmRadius.card),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ClockRhythmSpace.space16,
            ClockRhythmSpace.space12,
            ClockRhythmSpace.space16,
            ClockRhythmSpace.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        monthLabel,
                        key: const ValueKey<String>('todo-date-month'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('todo-date-previous-month'),
                    onPressed: previousMonth == null
                        ? null
                        : () => _showMonth(previousMonth),
                    tooltip: localizations.calendarPreviousMonth,
                    icon: const LineIcon(LineGlyph.chevronLeft),
                  ),
                  TextButton(
                    key: const ValueKey<String>('todo-date-today'),
                    onPressed: () =>
                        _showMonth(TodoDateMath.firstOfMonth(widget.today)),
                    child: Text(localizations.calendarToday),
                  ),
                  IconButton(
                    key: const ValueKey<String>('todo-date-next-month'),
                    onPressed: nextMonth == null
                        ? null
                        : () => _showMonth(nextMonth),
                    tooltip: localizations.calendarNextMonth,
                    icon: const LineIcon(LineGlyph.chevronRight),
                  ),
                ],
              ),
              const SizedBox(height: ClockRhythmSpace.space8),
              ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    for (final String weekday in weekdays)
                      Expanded(
                        child: Text(
                          weekday,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: _cellSpacing,
                  mainAxisSpacing: _cellSpacing,
                  mainAxisExtent: cellHeight,
                ),
                itemCount: cells.length,
                itemBuilder: (BuildContext context, int index) {
                  final LocalCalendarDate? date = cells[index].date;
                  if (date == null) {
                    return const SizedBox.shrink();
                  }
                  return _DateCell(
                    date: date,
                    label: formatter.formatFullDate(
                      TodoDateMath.toLocalDateTime(date),
                    ),
                    summary: summary[date.text],
                    isSelected: date == widget.selected,
                    isToday: date == widget.today,
                    onPressed: widget.enabled
                        ? () => widget.onSelected(date)
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Drops trailing weeks that hold no day of the month.
  List<CalendarCell> _visibleRows(List<CalendarCell> cells) {
    final int lastDayIndex = cells.lastIndexWhere(
      (CalendarCell cell) => cell.isCurrentMonth,
    );
    final int rows = lastDayIndex ~/ 7 + 1;
    return cells.sublist(0, rows * 7);
  }
}

final class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.label,
    required this.summary,
    required this.isSelected,
    required this.isToday,
    required this.onPressed,
  });

  final LocalCalendarDate date;
  final String label;
  final TodoDaySummary? summary;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context);
    final TodoDaySummary? daySummary = summary;
    final bool hasTodos = daySummary != null && daySummary.total > 0;
    final BorderRadius radius = BorderRadius.circular(
      ClockRhythmRadius.control,
    );
    return Semantics(
      button: true,
      selected: isSelected,
      label: <String>[
        label,
        if (hasTodos) localizations.calendarDayTodoCount(daySummary.total),
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey<String>('todo-date-${date.text}'),
          onTap: onPressed,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryContainer : null,
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? colors.primary : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    date.day.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isToday ? colors.onPrimary : colors.onSurface,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hasTodos ? colors.secondary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
