import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/presentation/todo_schedule_dialog.dart';
import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/todo_presentation_test_support.dart';

void main() {
  const ValueKey<String> hourField = ValueKey<String>('todo-time-hour');
  const ValueKey<String> minuteField = ValueKey<String>('todo-time-minute');
  const ValueKey<String> invalid = ValueKey<String>('todo-time-invalid');
  const ValueKey<String> clearTime = ValueKey<String>(
    'todo-schedule-clear-time',
  );
  const ValueKey<String> confirm = ValueKey<String>('todo-schedule-confirm');
  final LocalCalendarDate june2 = LocalCalendarDate.parse('2026-06-02');

  /// Opens the dialog and returns where its outcome lands: an empty list
  /// while it is open, then the single value it completed with.
  Future<List<TodoSchedule?>> openDialog(
    WidgetTester tester, {
    required String? time,
    TargetPlatform platform = TargetPlatform.windows,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    final List<TodoSchedule?> outcomes = <TodoSchedule?>[];
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: TestTodoRepository(),
        dateClock: dateClock,
        textScaler: textScaler,
        theme: ClockRhythmTheme.build(
          ThemeCatalog.resolve(ThemePreference.current),
          platform: platform,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                outcomes.add(
                  await showTodoScheduleDialog(
                    context: context,
                    initial: (date: june2, time: time),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return outcomes;
  }

  String textOf(WidgetTester tester, ValueKey<String> field) {
    return tester.widget<TextField>(find.byKey(field)).controller!.text;
  }

  bool canConfirm(WidgetTester tester) {
    return tester.widget<FilledButton>(find.byKey(confirm)).onPressed != null;
  }

  testWidgets('confirming returns the typed 24-hour time on the same date', (
    WidgetTester tester,
  ) async {
    final List<TodoSchedule?> outcomes = await openDialog(
      tester,
      time: '19:39',
    );

    expect(find.text('Edit Todo date and time'), findsOneWidget);
    expect(textOf(tester, hourField), '19');
    expect(textOf(tester, minuteField), '39');

    await tester.enterText(find.byKey(hourField), '7');
    await tester.enterText(find.byKey(minuteField), '05');
    await tester.tap(find.byKey(confirm));
    await tester.pumpAndSettle();

    expect(outcomes, <TodoSchedule?>[(date: june2, time: '07:05')]);
  });

  testWidgets('the hour steps by one and wraps past midnight', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, time: '23:00');

    await tester.tap(
      find.byKey(const ValueKey<String>('todo-time-hour-increase')),
    );
    await tester.pump();
    expect(textOf(tester, hourField), '00');

    await tester.tap(
      find.byKey(const ValueKey<String>('todo-time-hour-decrease')),
    );
    await tester.pump();
    expect(textOf(tester, hourField), '23');
  });

  testWidgets('the minute steps to the nearest five-minute stop and wraps', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, time: '19:39');
    final Finder increase = find.byKey(
      const ValueKey<String>('todo-time-minute-increase'),
    );
    final Finder decrease = find.byKey(
      const ValueKey<String>('todo-time-minute-decrease'),
    );

    await tester.tap(increase);
    await tester.pump();
    expect(textOf(tester, minuteField), '40');

    await tester.enterText(find.byKey(minuteField), '39');
    await tester.tap(decrease);
    await tester.pump();
    expect(textOf(tester, minuteField), '35');

    await tester.enterText(find.byKey(minuteField), '55');
    await tester.tap(increase);
    await tester.pump();
    expect(textOf(tester, minuteField), '00');

    await tester.tap(decrease);
    await tester.pump();
    expect(textOf(tester, minuteField), '55');
    expect(textOf(tester, hourField), '19');
  });

  testWidgets('arrow keys step the focused part', (WidgetTester tester) async {
    await openDialog(tester, time: '09:30');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(textOf(tester, hourField), '10');

    await tester.tap(find.byKey(minuteField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(textOf(tester, minuteField), '25');
  });

  testWidgets('an out-of-range part explains itself and blocks confirming', (
    WidgetTester tester,
  ) async {
    final List<TodoSchedule?> outcomes = await openDialog(
      tester,
      time: '19:39',
    );
    expect(find.byKey(invalid), findsNothing);

    await tester.enterText(find.byKey(hourField), '24');
    await tester.pump();
    expect(find.byKey(invalid), findsOneWidget);
    expect(canConfirm(tester), isFalse);

    await tester.enterText(find.byKey(hourField), '23');
    await tester.enterText(find.byKey(minuteField), '60');
    await tester.pump();
    expect(find.byKey(invalid), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(outcomes, isEmpty);

    await tester.enterText(find.byKey(minuteField), '59');
    await tester.pump();
    expect(find.byKey(invalid), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(outcomes, <TodoSchedule?>[(date: june2, time: '23:59')]);
  });

  testWidgets('a Todo without a time opens empty and stays without one', (
    WidgetTester tester,
  ) async {
    final List<TodoSchedule?> outcomes = await openDialog(tester, time: null);

    expect(textOf(tester, hourField), isEmpty);
    expect(textOf(tester, minuteField), isEmpty);
    expect(find.byKey(invalid), findsNothing);
    expect(tester.widget<TextButton>(find.byKey(clearTime)).onPressed, isNull);

    await tester.tap(find.byKey(confirm));
    await tester.pumpAndSettle();

    expect(outcomes, <TodoSchedule?>[(date: june2, time: null)]);
  });

  testWidgets('clearing empties both parts and half a time is not a time', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, time: '19:39');

    await tester.tap(find.byKey(clearTime));
    await tester.pump();
    expect(textOf(tester, hourField), isEmpty);
    expect(textOf(tester, minuteField), isEmpty);
    expect(find.byKey(invalid), findsNothing);
    expect(canConfirm(tester), isTrue);

    await tester.enterText(find.byKey(hourField), '8');
    await tester.pump();
    expect(find.byKey(invalid), findsOneWidget);
    expect(canConfirm(tester), isFalse);
  });

  testWidgets('stepping out of an empty time starts the other part at zero', (
    WidgetTester tester,
  ) async {
    final List<TodoSchedule?> outcomes = await openDialog(tester, time: null);

    await tester.tap(
      find.byKey(const ValueKey<String>('todo-time-hour-increase')),
    );
    await tester.pump();
    expect(textOf(tester, hourField), '01');
    expect(textOf(tester, minuteField), '00');

    await tester.tap(find.byKey(confirm));
    await tester.pumpAndSettle();
    expect(outcomes, <TodoSchedule?>[(date: june2, time: '01:00')]);
  });

  testWidgets('the month picks another date and keeps the time', (
    WidgetTester tester,
  ) async {
    final List<TodoSchedule?> outcomes = await openDialog(
      tester,
      time: '14:30',
    );

    expect(find.text('June 2026'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('todo-date-next-month')),
    );
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);
    final Finder day = find.byKey(
      const ValueKey<String>('todo-date-2026-07-14'),
    );
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(confirm));
    await tester.tap(find.byKey(confirm));
    await tester.pumpAndSettle();

    expect(outcomes, <TodoSchedule?>[
      (date: LocalCalendarDate.parse('2026-07-14'), time: '14:30'),
    ]);
  });

  testWidgets('cancelling returns no schedule', (WidgetTester tester) async {
    final List<TodoSchedule?> outcomes = await openDialog(
      tester,
      time: '19:39',
    );

    await tester.enterText(find.byKey(hourField), '8');
    final Finder cancel = find.byKey(
      const ValueKey<String>('todo-schedule-cancel'),
    );
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(outcomes, <TodoSchedule?>[null]);
  });

  testWidgets('a narrow window with doubled text keeps every control usable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openDialog(
      tester,
      time: '19:39',
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    for (final String control in <String>[
      'todo-time-hour-increase',
      'todo-time-hour-decrease',
      'todo-time-minute-increase',
      'todo-time-minute-decrease',
    ]) {
      final Size size = tester.getSize(find.byKey(ValueKey<String>(control)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    for (final ValueKey<String> control in <ValueKey<String>>[
      const ValueKey<String>('todo-date-2026-06-30'),
      confirm,
    ]) {
      await tester.ensureVisible(find.byKey(control));
      expect(find.byKey(control).hitTestable(), findsOneWidget);
    }
  });

  testWidgets('a phone shows the same dialog with reachable days', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openDialog(tester, time: '14:30', platform: TargetPlatform.android);

    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsOneWidget);
    final Finder day = find.byKey(
      const ValueKey<String>('todo-date-2026-06-30'),
    );
    await tester.ensureVisible(day);
    expect(day.hitTestable(), findsOneWidget);
  });
}
