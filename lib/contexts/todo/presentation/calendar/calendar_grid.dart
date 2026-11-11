import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
import '../../../../shared/ui/public.dart'
    show ClockRhythmRadius, ClockRhythmSpace, FocusRing;
import '../../domain/local_calendar_date.dart';
import '../../domain/todo_collection.dart';
import '../todo_date_math.dart';
import '../todo_view_state.dart';
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
  static const double _cellSpacing = ClockRhythmSpace.space4;
  static const double _minimumCellWidth = 56;
  static const double _roomyCellMinimumWidth = 80;

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
          final double cellWidth = (gridWidth - _cellSpacing * 6) / 7;
          // Roomy cells read like a planner: the date at the top-left and
          // the day's Todo count beneath it. Compact cells centre the date
          // over a dot.
          final bool compact = cellWidth < _roomyCellMinimumWidth;
          final double cellHeight =
              (compact ? 52 : 72) + math.max(0, scale - 1) * 44;
          final double gridHeight = cellHeight * 6 + _cellSpacing * 5;
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
                          child: Container(
                            width: cellWidth,
                            padding: EdgeInsetsDirectional.only(
                              start: compact ? 0 : ClockRhythmSpace.space8,
                            ),
                            child: ExcludeSemantics(
                              child: Text(
                                weekdays[index],
                                textAlign: compact
                                    ? TextAlign.center
                                    : TextAlign.start,
                                style: Theme.of(context).textTheme.labelSmall,
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
                            compact: compact,
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
      child: SizedBox.expand(key: ValueKey<String>('calendar-blank-$index')),
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
    required this.compact,
    required this.onTap,
  });

  final LocalCalendarDate date;
  final int day;
  final TodoDaySummary? summary;
  final bool isSelected;
  final bool isToday;
  final bool enabled;
  final bool compact;
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
    final ColorScheme colors = theme.colorScheme;
    final double numberSize = compact ? 28 : 26;
    final Widget number = Container(
      constraints: BoxConstraints(minWidth: numberSize, minHeight: numberSize),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isToday ? colors.primary : null,
        borderRadius: BorderRadius.circular(ClockRhythmRadius.pill),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          day.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isToday ? colors.onPrimary : colors.onSurface,
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
    final Widget body = compact
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              number,
              const SizedBox(height: 3),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: daySummary == null ? null : colors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 4),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                number,
                if (daySummary != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Text(
                      localizations.calendarDayTodoCount(daySummary.total),
                      key: ValueKey<String>('calendar-summary-${date.text}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );

    return Semantics(
      key: ValueKey<String>('calendar-day-${date.text}'),
      label: semanticsParts.join(', '),
      button: true,
      enabled: enabled,
      selected: isSelected,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: Material(
        color: isSelected
            ? Color.lerp(colors.surface, colors.primary, 0.2)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            compact ? ClockRhythmRadius.control + 2 : ClockRhythmRadius.control,
          ),
          side: isSelected
              ? BorderSide(color: colors.primary)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          canRequestFocus: false,
          onTap: enabled ? onTap : null,
          child: body,
        ),
      ),
    );
  }
}
