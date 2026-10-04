import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
import '../../../../shared/ui/public.dart'
    show
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmPageHeader,
        ClockRhythmSpace;
import '../../domain/local_calendar_date.dart';
import '../todo_date_math.dart';
import '../todo_editor.dart';
import '../todo_list_panel.dart';
import '../todo_providers.dart';
import '../todo_status_message.dart';
import '../todo_view_model.dart';
import 'calendar_grid.dart';
import 'calendar_header.dart';

final class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({
    this.initialSelectedDate,
    this.onSelectedDateChanged,
    super.key,
  });

  final LocalCalendarDate? initialSelectedDate;
  final ValueChanged<LocalCalendarDate>? onSelectedDateChanged;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

final class _CalendarPageState extends ConsumerState<CalendarPage>
    with RestorationMixin {
  final RestorableDouble _restoredScrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  )..addListener(_recordScrollOffset);
  bool _scrollRestorePending = false;

  @override
  String? get restorationId => 'calendar_page';

  @override
  void initState() {
    super.initState();
    _scheduleRouteDateSynchronization();
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedDate != widget.initialSelectedDate) {
      _scheduleRouteDateSynchronization();
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restoredScrollOffset, 'scroll_offset');
    _scrollRestorePending = _restoredScrollOffset.value > 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final AsyncValue<TodoViewState> asyncState = ref.watch(
      todoViewModelProvider,
    );
    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('calendar-page-scroll'),
        controller: _scrollController,
        padding: ClockRhythmLayout.pageInsetsFor(
          MediaQuery.sizeOf(context).width,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClockRhythmPageHeader(
              eyebrow: localizations.calendarEyebrow,
              title: localizations.calendarTitle,
            ),
            asyncState.when<Widget>(
              data: (TodoViewState state) {
                _scheduleRestoredScrollOffset();
                return _CalendarPageContent(
                  state: state,
                  onSelectedDateChanged: widget.onSelectedDateChanged,
                );
              },
              error: (Object error, StackTrace stackTrace) => TodoLoadFailure(
                onRetry: () {
                  ref.invalidate(todoViewModelProvider);
                  _scheduleRouteDateSynchronization();
                },
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(ClockRhythmSpace.space32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleRouteDateSynchronization() {
    final LocalCalendarDate? routeDate = widget.initialSelectedDate;
    if (routeDate == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((Duration elapsed) {
      unawaited(_synchronizeRouteDate(routeDate));
    });
  }

  Future<void> _synchronizeRouteDate(LocalCalendarDate routeDate) async {
    try {
      await ref.read(todoViewModelProvider.future);
    } on Object {
      return;
    }
    if (!mounted || widget.initialSelectedDate != routeDate) {
      return;
    }
    await ref
        .read(todoViewModelProvider.notifier)
        .synchronizeSelectedDate(routeDate);
  }

  void _recordScrollOffset() {
    if (!_scrollRestorePending && _scrollController.hasClients) {
      _restoredScrollOffset.value = _scrollController.offset;
    }
  }

  void _scheduleRestoredScrollOffset() {
    if (!_scrollRestorePending) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((Duration elapsed) {
      if (!mounted || !_scrollRestorePending || !_scrollController.hasClients) {
        return;
      }
      final ScrollPosition position = _scrollController.position;
      final double target = _restoredScrollOffset.value.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _scrollRestorePending = false;
      _scrollController.jumpTo(target);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _restoredScrollOffset.dispose();
    super.dispose();
  }
}

final class _CalendarPageContent extends ConsumerWidget {
  const _CalendarPageContent({
    required this.state,
    required this.onSelectedDateChanged,
  });

  final TodoViewState state;
  final ValueChanged<LocalCalendarDate>? onSelectedDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TodoViewModel viewModel = ref.read(todoViewModelProvider.notifier);
    final Widget calendarBoard = ClockRhythmCard.unpadded(
      key: const ValueKey<String>('calendar-board'),
      child: Padding(
        padding: EdgeInsets.all(
          ClockRhythmLayout.cardPaddingFor(MediaQuery.sizeOf(context).width),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CalendarHeader(
              state: state,
              onMoveMonth: viewModel.moveVisibleMonth,
              onGoToToday: () async {
                await viewModel.goToToday();
                onSelectedDateChanged?.call(state.todayDate);
              },
            ),
            const SizedBox(height: ClockRhythmSpace.space12),
            CalendarGrid(
              state: state,
              onSelectDate: (LocalCalendarDate date) async {
                await viewModel.selectDate(date);
                onSelectedDateChanged?.call(date);
              },
            ),
          ],
        ),
      ),
    );
    final Widget selectedDatePanel = _SelectedDatePanel(state: state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double scaledBody = MediaQuery.textScalerOf(
              context,
            ).scale(16);
            final bool useTwoColumns =
                constraints.maxWidth >= 900 && scaledBody <= 24;
            if (!useTwoColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  calendarBoard,
                  const SizedBox(height: ClockRhythmSpace.space16),
                  selectedDatePanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 6, child: calendarBoard),
                const SizedBox(width: ClockRhythmSpace.space20),
                Expanded(flex: 4, child: selectedDatePanel),
              ],
            );
          },
        ),
      ],
    );
  }
}

final class _SelectedDatePanel extends StatefulWidget {
  const _SelectedDatePanel({required this.state});

  final TodoViewState state;

  @override
  State<_SelectedDatePanel> createState() => _SelectedDatePanelState();
}

final class _SelectedDatePanelState extends State<_SelectedDatePanel> {
  final FocusNode _composerFocus = FocusNode(debugLabel: 'Calendar composer');
  TodoViewState get state => widget.state;

  @override
  void dispose() {
    _composerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final LocalDateFormatter formatter = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final String formattedDate = formatter.formatFullDate(
      TodoDateMath.toLocalDateTime(state.selectedDate),
    );
    return ClockRhythmCard.unpadded(
      key: const ValueKey<String>('calendar-selected-date-panel'),
      child: Padding(
        padding: EdgeInsets.all(
          ClockRhythmLayout.cardPaddingFor(MediaQuery.sizeOf(context).width),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              localizations.calendarSelectedEyebrow,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: ClockRhythmSpace.space4),
            Semantics(
              header: true,
              label: localizations.calendarSelectedDateLabel(formattedDate),
              excludeSemantics: true,
              child: Text(
                formattedDate,
                key: const ValueKey<String>('calendar-selected-date'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: ClockRhythmSpace.space12),
            TodoEditor.forDate(
              key: ValueKey<String>(
                'calendar-editor-${state.selectedDate.text}',
              ),
              date: state.selectedDate,
              focusNode: _composerFocus,
            ),
            TodoListPanel(
              key: ValueKey<String>('calendar-list-${state.selectedDate.text}'),
              todos: state.selectedDateTodos,
              onEditedRowRemoved: () {
                if (mounted && TickerMode.valuesOf(context).enabled) {
                  _composerFocus.requestFocus();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
