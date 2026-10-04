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
import '../todo_view_model.dart';

final class TodayTodoPanel extends ConsumerWidget {
  const TodayTodoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final AsyncValue<TodoViewState> asyncState = ref.watch(
      todoViewModelProvider,
    );
    return ClockRhythmCard.padded(
      key: const ValueKey<String>('today-todo-panel'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              localizations.todoTodayEyebrow,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            localizations.todoTodayTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: ClockRhythmSpace.space4),
          asyncState.when<Widget>(
            data: (TodoViewState state) => _TodayTodoContent(state: state),
            error: (Object error, StackTrace stackTrace) => TodoLoadFailure(
              onRetry: () {
                ref.invalidate(todoViewModelProvider);
              },
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(ClockRhythmSpace.space24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _TodayTodoContent extends StatefulWidget {
  const _TodayTodoContent({required this.state});

  final TodoViewState state;

  @override
  State<_TodayTodoContent> createState() => _TodayTodoContentState();
}

final class _TodayTodoContentState extends State<_TodayTodoContent> {
  final FocusNode _composerFocus = FocusNode(debugLabel: 'Today composer');
  TodoViewState get state => widget.state;

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
        Text(
          formattedDate,
          key: const ValueKey<String>('today-date'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: ClockRhythmSpace.space12),
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
