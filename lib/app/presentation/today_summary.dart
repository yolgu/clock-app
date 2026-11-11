import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contexts/rhythm/public_presentation.dart'
    show RhythmStatusText, RhythmViewState, rhythmViewModelProvider;
import '../../contexts/todo/public_presentation.dart'
    show TodoDataState, todoDataControllerProvider;
import '../../shared/i18n/public.dart' show AppLocalizations;
import '../../shared/ui/public.dart' show ClockRhythmSpace;

/// Today at a glance for the sidebar: open Todos, the focus window and the
/// session state. Facts that have not loaded yet are left out.
final class TodaySummary extends ConsumerWidget {
  const TodaySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final TodoDataState? todos = ref.watch(todoDataControllerProvider).value;
    final RhythmViewState? rhythm = ref.watch(rhythmViewModelProvider).value;
    final TextStyle? valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return DecoratedBox(
      key: const ValueKey<String>('sidebar-today-summary'),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ClockRhythmSpace.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                copy.sidebarTodayTitle,
                style: theme.textTheme.labelSmall,
              ),
            ),
            if (todos != null)
              _Fact(
                label: copy.sidebarOpenTodos,
                value: Text(
                  todos.todayTodos
                      .where((todo) => !todo.completed)
                      .length
                      .toString(),
                  style: valueStyle,
                ),
              ),
            if (rhythm != null) ...<Widget>[
              _Fact(
                label: copy.sidebarFocusWindow,
                value: Text(_focusWindow(rhythm), style: valueStyle),
              ),
              _Fact(
                label: copy.rhythmStatusTitle,
                value: RhythmStatusText(
                  snapshot: rhythm.snapshot,
                  style: valueStyle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The focus window as the clock times it opens and closes.
String _focusWindow(RhythmViewState rhythm) {
  final String start = rhythm.snapshot.configuration.dailyRhythm.start.text;
  final String end = rhythm.snapshot.configuration.dailyRhythm.end.text;
  return '$start–$end';
}

final class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ClockRhythmSpace.space8),
      child: MergeSemantics(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            value,
          ],
        ),
      ),
    );
  }
}
