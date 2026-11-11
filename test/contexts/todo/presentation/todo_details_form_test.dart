import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/todo_presentation_test_support.dart';

void main() {
  const ValueKey<String> save = ValueKey<String>('todo-save');
  const ValueKey<String> cancel = ValueKey<String>('todo-cancel');

  Future<TestTodoRepository> openDetails(
    WidgetTester tester, {
    required TargetPlatform platform,
    required Size viewport,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'todo-1', title: 'Timed', time: '14:30'),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        textScaler: textScaler,
        theme: ClockRhythmTheme.build(
          ThemeCatalog.resolve(ThemePreference.current),
          platform: platform,
        ),
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();
    final Finder details = find.byKey(
      const ValueKey<String>('todo-edit-todo-1'),
    );
    await tester.ensureVisible(details);
    await tester.pumpAndSettle();
    await tester.tap(details);
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('the edit form names its fields and saves a cleared time', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = await openDetails(
      tester,
      platform: TargetPlatform.windows,
      viewport: const Size(1100, 800),
    );

    expect(find.text('Edit Todo'), findsOneWidget);
    for (final String label in <String>['Title', 'Date', 'Time']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Tuesday, June 2, 2026'),
      ),
      findsOneWidget,
    );

    Finder inDialog(Finder finder) =>
        find.descendant(of: find.byType(Dialog), matching: finder);
    await tester.tap(
      inDialog(find.byKey(const ValueKey<String>('todo-clear-time'))),
    );
    await tester.pump();
    expect(
      inDialog(find.byKey(const ValueKey<String>('todo-add-time'))),
      findsOneWidget,
    );
    expect(inDialog(find.text('Add time')), findsOneWidget);

    await tester.tap(find.byKey(save));
    await tester.pumpAndSettle();

    expect(repository.todos.single.time, isNull);
    expect(find.text('Edit Todo'), findsNothing);
  });

  testWidgets('a dialog ends with Cancel before Save on one line', (
    WidgetTester tester,
  ) async {
    await openDetails(
      tester,
      platform: TargetPlatform.windows,
      viewport: const Size(1100, 800),
    );

    final Rect cancelRect = tester.getRect(find.byKey(cancel));
    final Rect saveRect = tester.getRect(find.byKey(save));
    expect(find.byType(Dialog), findsOneWidget);
    expect(cancelRect.center.dy, saveRect.center.dy);
    expect(cancelRect.right, lessThan(saveRect.left));
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('todo-edit-date'))).top,
      tester.getRect(find.byKey(const ValueKey<String>('todo-edit-time'))).top,
    );
  });

  testWidgets('a sheet stacks full-width Save over Cancel', (
    WidgetTester tester,
  ) async {
    await openDetails(
      tester,
      platform: TargetPlatform.android,
      viewport: const Size(390, 844),
    );

    final Rect cancelRect = tester.getRect(find.byKey(cancel));
    final Rect saveRect = tester.getRect(find.byKey(save));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(saveRect.width, cancelRect.width);
    expect(saveRect.width, greaterThan(300));
    expect(saveRect.bottom, lessThan(cancelRect.top));
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('todo-edit-date'))).top,
      lessThan(
        tester
            .getRect(find.byKey(const ValueKey<String>('todo-edit-time')))
            .top,
      ),
    );
  });

  testWidgets('the sheet stays usable at 200-percent text', (
    WidgetTester tester,
  ) async {
    await openDetails(
      tester,
      platform: TargetPlatform.android,
      viewport: const Size(360, 800),
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(save));
    expect(find.byKey(save).hitTestable(), findsOneWidget);
  });

  testWidgets('the date field unfolds a month that picks the date', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = await openDetails(
      tester,
      platform: TargetPlatform.windows,
      viewport: const Size(1100, 900),
    );
    const ValueKey<String> datePanel = ValueKey<String>('todo-date-panel');
    const ValueKey<String> timePanel = ValueKey<String>('todo-time-panel');

    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-date')));
    await tester.pumpAndSettle();
    expect(find.byKey(datePanel), findsOneWidget);
    expect(find.text('June 2026'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-time')));
    await tester.pumpAndSettle();
    expect(find.byKey(datePanel), findsNothing);
    expect(find.byKey(timePanel), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-date')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('todo-date-next-month')),
    );
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('todo-date-2026-07-14')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(datePanel), findsNothing);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Tuesday, July 14, 2026'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(save));
    await tester.pumpAndSettle();
    expect(repository.todos.single.date.text, '2026-07-14');
  });

  testWidgets('an hour keeps the time panel open and a minute closes it', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = await openDetails(
      tester,
      platform: TargetPlatform.windows,
      viewport: const Size(1100, 900),
    );
    const ValueKey<String> timePanel = ValueKey<String>('todo-time-panel');

    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('todo-hour-09')));
    await tester.pumpAndSettle();
    expect(find.byKey(timePanel), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('09:30')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('todo-minute-45')));
    await tester.pumpAndSettle();
    expect(find.byKey(timePanel), findsNothing);

    await tester.tap(find.byKey(save));
    await tester.pumpAndSettle();
    expect(repository.todos.single.time?.text, '09:45');
  });

  testWidgets('a sheet with an open month stays usable at 200-percent text', (
    WidgetTester tester,
  ) async {
    await openDetails(
      tester,
      platform: TargetPlatform.android,
      viewport: const Size(360, 800),
      textScaler: const TextScaler.linear(2),
    );
    final Finder date = find.byKey(const ValueKey<String>('todo-edit-date'));
    await tester.ensureVisible(date);
    await tester.tap(date);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final Finder day = find.byKey(
      const ValueKey<String>('todo-date-2026-06-30'),
    );
    await tester.ensureVisible(day);
    expect(day.hitTestable(), findsOneWidget);
  });
}
