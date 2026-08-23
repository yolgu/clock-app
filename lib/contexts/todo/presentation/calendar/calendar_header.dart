import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
import '../todo_date_math.dart';
import '../todo_view_model.dart';

final class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    required this.state,
    required this.onMoveMonth,
    required this.onGoToToday,
    super.key,
  });

  final TodoViewState state;
  final Future<void> Function(int offset) onMoveMonth;
  final Future<void> Function() onGoToToday;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final LocalDateFormatter formatter = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final String monthLabel = formatter.formatMonth(
      TodoDateMath.toLocalDateTime(state.visibleMonth),
    );
    final bool canMovePrevious =
        TodoDateMath.addMonths(state.visibleMonth, -1) != null;
    final bool canMoveNext =
        TodoDateMath.addMonths(state.visibleMonth, 1) != null;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              localizations.calendarMonthEyebrow,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Semantics(
              header: true,
              child: Text(
                monthLabel,
                key: const ValueKey<String>('calendar-month-label'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: <Widget>[
            IconButton(
              key: const ValueKey<String>('calendar-previous-month'),
              onPressed: canMovePrevious && !state.isMutating
                  ? () {
                      unawaited(onMoveMonth(-1));
                    }
                  : null,
              tooltip: localizations.calendarPreviousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton(
              key: const ValueKey<String>('calendar-today'),
              onPressed: state.isMutating
                  ? null
                  : () {
                      unawaited(onGoToToday());
                    },
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(localizations.calendarToday),
            ),
            IconButton(
              key: const ValueKey<String>('calendar-next-month'),
              onPressed: canMoveNext && !state.isMutating
                  ? () {
                      unawaited(onMoveMonth(1));
                    }
                  : null,
              tooltip: localizations.calendarNextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
