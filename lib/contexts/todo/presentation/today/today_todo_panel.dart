import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
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
    return Card(
      key: const ValueKey<String>('today-todo-panel'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                localizations.todoTodayEyebrow,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              localizations.todoTodayTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            asyncState.when<Widget>(
              data: (TodoViewState state) => _TodayTodoContent(state: state),
              error: (Object error, StackTrace stackTrace) => TodoLoadFailure(
                onRetry: () {
                  ref.invalidate(todoViewModelProvider);
                },
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TodayTodoContent extends StatelessWidget {
  const _TodayTodoContent({required this.state});

  final TodoViewState state;

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
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TodoEditor.today(
          key: const ValueKey<String>('today-todo-editor'),
          date: state.todayDate,
        ),
        TodoStatusMessage(
          message: state.message,
          messageSerial: state.messageSerial,
        ),
        TodoListPanel(
          key: const ValueKey<String>('today-todo-list'),
          todos: state.todayTodos,
        ),
      ],
    );
  }
}
