import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
import '../../../../shared/ui/public.dart'
    show ClockRhythmCard, ClockRhythmSpace;
import '../todo_date_math.dart';
import '../todo_editor.dart';
import '../todo_list_panel.dart';
import '../todo_providers.dart';
import '../todo_status_message.dart';

final class TodayTodoPanel extends ConsumerWidget {
  const TodayTodoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TodoDataState> asyncState = ref.watch(
      todoDataControllerProvider,
    );
    return ClockRhythmCard.padded(
      key: const ValueKey<String>('today-todo-panel'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          asyncState.when<Widget>(
            data: (TodoDataState state) => _TodayTodoContent(state: state),
            error: (Object error, StackTrace stackTrace) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _TodayHeader(),
                TodoLoadFailure(
                  onRetry: () {
                    ref.invalidate(todoDataControllerProvider);
                  },
                ),
              ],
            ),
            loading: () => const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _TodayHeader(),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(ClockRhythmSpace.space24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _TodayTodoContent extends StatefulWidget {
  const _TodayTodoContent({required this.state});

  final TodoDataState state;

  @override
  State<_TodayTodoContent> createState() => _TodayTodoContentState();
}

final class _TodayTodoContentState extends State<_TodayTodoContent> {
  final FocusNode _composerFocus = FocusNode(debugLabel: 'Today composer');
  TodoDataState get state => widget.state;

  @override
  void dispose() {
    _composerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalDateFormatter formatter = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final String formattedDate = formatter.formatFullDate(
      TodoDateMath.toLocalDateTime(state.todayDate),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _TodayHeader(
          date: formattedDate,
          count: AppLocalizations.of(
            context,
          ).todoCount(state.todayTodos.length),
        ),
        const SizedBox(height: ClockRhythmSpace.space8),
        TodoEditor.today(
          key: const ValueKey<String>('today-todo-editor'),
          date: state.todayDate,
          focusNode: _composerFocus,
        ),
        TodoListPanel(
          key: const ValueKey<String>('today-todo-list'),
          todos: state.todayTodos,
          onEditedRowRemoved: () {
            if (mounted && TickerMode.valuesOf(context).enabled) {
              _composerFocus.requestFocus();
            }
          },
        ),
      ],
    );
  }
}

/// The card title with today's date underneath and the Todo count opposite.
final class _TodayHeader extends StatelessWidget {
  const _TodayHeader({this.date, this.count});

  final String? date;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  AppLocalizations.of(context).todoTodayTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (date case final String value)
                Text(
                  value,
                  key: const ValueKey<String>('today-date'),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (count case final String value) ...<Widget>[
          const SizedBox(width: ClockRhythmSpace.space12),
          Text(value, style: theme.textTheme.labelSmall),
        ],
      ],
    );
  }
}
