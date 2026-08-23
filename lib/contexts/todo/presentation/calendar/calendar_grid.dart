import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
import '../../../../shared/ui/public.dart' show FocusRing;
import '../../domain/local_calendar_date.dart';
import '../../domain/todo_collection.dart';
import '../todo_date_math.dart';
import '../todo_view_model.dart';
import 'calendar_cells.dart';

final class CalendarGrid extends StatefulWidget {
  const CalendarGrid({
    required this.state,
    required this.onSelectDate,
    super.key,
  });

  final TodoViewState state;
  final Future<void> Function(LocalCalendarDate date) onSelectDate;

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

final class _CalendarGridState extends State<CalendarGrid> {
  static const double _cellSpacing = 4;
  static const double _minimumCellWidth = 56;

  late final List<FocusNode> _focusNodes = List<FocusNode>.generate(
    CalendarCells.fixedCellCount,
    (int index) => FocusNode(debugLabel: 'calendar cell $index'),
    growable: false,
  );
  @override
  void dispose() {
    for (final FocusNode focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final LocalDateFormatter formatter = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final List<CalendarCell> cells = CalendarCells.forMonth(
      widget.state.visibleMonth,
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
    final String monthLabel = formatter.formatMonth(
      TodoDateMath.toLocalDateTime(widget.state.visibleMonth),
    );
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    final double cellHeight = 64 + math.max(0, scale - 1) * 28;

    return Semantics(
      container: true,
      label: localizations.calendarGridLabel(monthLabel),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double minimumGridWidth =
              _minimumCellWidth * 7 + _cellSpacing * 6;
          final double gridWidth = math.max(
            constraints.maxWidth,
            minimumGridWidth,
          );
          final double gridHeight = cellHeight * 6 + _cellSpacing * 5;
          final double cellWidth = (gridWidth - _cellSpacing * 6) / 7;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: gridWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      for (int index = 0; index < weekdays.length; index += 1)
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: index == weekdays.length - 1
                                ? 0
                                : _cellSpacing,
                          ),
                          child: SizedBox(
                            width: cellWidth,
                            child: ExcludeSemantics(
                              child: Text(
                                weekdays[index],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: _cellSpacing),
                  SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
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
                        final CalendarCell cell = cells[index];
                        if (!cell.isCurrentMonth) {
                          return _CalendarBlankCell(index: index);
                        }
                        final LocalCalendarDate date = cell.date!;
                        return FocusRing(
                          focusNode: _focusNodes[index],
                          onKeyEvent: (FocusNode node, KeyEvent event) {
                            return _handleCellKey(event, index, cells);
                          },
                          child: _CalendarDayCell(
                            date: date,
                            day: cell.day!,
                            summary: widget.state.monthSummary[date.text],
                            isSelected: widget.state.selectedDate == date,
                            isToday: widget.state.todayDate == date,
                            enabled: !widget.state.isMutating,
                            onTap: () {
                              _focusNodes[index].requestFocus();
                              unawaited(widget.onSelectDate(date));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  KeyEventResult _handleCellKey(
    KeyEvent event,
    int currentIndex,
    List<CalendarCell> cells,
  ) {
    if (event is! KeyDownEvent || widget.state.isMutating) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final LocalCalendarDate? currentDate = cells[currentIndex].date;
      if (currentDate != null) {
        unawaited(widget.onSelectDate(currentDate));
      }
      return KeyEventResult.handled;
    }
    final int offset = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => 0,
    };
    if (offset == 0) {
      return KeyEventResult.ignored;
    }
    final int targetIndex = currentIndex + offset;
    if (targetIndex < 0 ||
        targetIndex >= cells.length ||
        !cells[targetIndex].isCurrentMonth) {
      return KeyEventResult.handled;
    }
    final LocalCalendarDate targetDate = cells[targetIndex].date!;
    _focusNodes[targetIndex].requestFocus();
    unawaited(widget.onSelectDate(targetDate));
    return KeyEventResult.handled;
  }
}

final class _CalendarBlankCell extends StatelessWidget {
  const _CalendarBlankCell({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      enabled: false,
      child: DecoratedBox(
        key: ValueKey<String>('calendar-blank-$index'),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

final class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.day,
    required this.summary,
    required this.isSelected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
  });

  final LocalCalendarDate date;
  final int day;
  final TodoDaySummary? summary;
  final bool isSelected;
  final bool isToday;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    final LocalDateFormatter formatter = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final TodoDaySummary? daySummary = summary;
    final List<String> semanticsParts = <String>[
      formatter.formatFullDate(TodoDateMath.toLocalDateTime(date)),
      if (daySummary == null)
        localizations.calendarNoTodo
      else ...<String>[
        localizations.calendarDayTodoCount(daySummary.total),
        localizations.todoCompletedCount(daySummary.completed),
      ],
      if (isToday) localizations.calendarToday,
      if (isSelected) localizations.accessibilitySelected,
    ];
    final String semanticsLabel = semanticsParts.join(', ');
    final String? visualSummary = daySummary == null
        ? null
        : '${daySummary.completed}/${daySummary.total}';
    final Color borderColor = isSelected
        ? theme.colorScheme.primary
        : isToday
        ? theme.colorScheme.secondary
        : theme.colorScheme.outlineVariant;
    final double borderWidth = isSelected ? 3 : 1;

    return Semantics(
      key: ValueKey<String>('calendar-day-${date.text}'),
      label: semanticsLabel,
      button: true,
      enabled: enabled,
      selected: isSelected,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: Material(
        color: daySummary == null
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          canRequestFocus: false,
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    day.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isSelected)
                  const Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Icon(Icons.check, size: 16),
                  )
                else if (isToday)
                  const Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Icon(Icons.today_outlined, size: 16),
                  ),
                if (daySummary != null && visualSummary != null)
                  Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.checklist, size: 14),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            visualSummary,
                            key: ValueKey<String>(
                              'calendar-summary-${date.text}',
                            ),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
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
