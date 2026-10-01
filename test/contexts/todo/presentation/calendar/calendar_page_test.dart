import 'dart:ui' show Tristate;

import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:clock_rhythm/shared/ui/public.dart' show ClockRhythmLayout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/todo_presentation_test_support.dart';

void main() {
  testWidgets(
    'renders 42 Sunday-first cells with blank nonselectable adjacency',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'open', title: 'Open'),
        createTestTodo(id: 'done', title: 'Done', completed: true),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2, 10),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: const CalendarPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(_findKeysWithPrefix('calendar-day-'), findsNWidgets(30));
      expect(_findKeysWithPrefix('calendar-blank-'), findsNWidgets(12));
      expect(find.text('1/2'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Tuesday, June 2, 2026.*2 Todos.*1 completed Todo.*Today.*Selected',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('calendar-day-2026-05-31')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('calendar-day-2026-07-01')),
        findsNothing,
      );
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey<String>('calendar-day-2026-06-02')),
            )
            .shortestSide,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('calendar-today')))
            .height,
        greaterThanOrEqualTo(48),
      );
    },
  );

  testWidgets(
    'LB-033 calendar Todos omit time copy when no optional time exists',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'quiet', title: 'Untimed Todo'),
        createTestTodo(
          id: 'timed',
          title: 'Timed Todo',
          time: '08:15',
          displayOrder: 1,
        ),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: const CalendarPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('todo-title-quiet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-time-quiet')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('todo-time-timed')),
        findsOneWidget,
      );
      expect(find.text('--:--'), findsNothing);
      expect(find.text('No time'), findsNothing);
    },
  );

  testWidgets(
    'synchronizes a valid route date and adds to that selected date',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository();
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: CalendarPage(
            initialSelectedDate: LocalCalendarDate.parse('2026-07-04'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
      expect(find.text('Saturday, July 4, 2026'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-create-title')),
        'Selected date Todo',
      );
      await tester.pump();
      final Finder addButton = find.byKey(const ValueKey<String>('todo-add'));
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(repository.todos.single.date.text, '2026-07-04');
      expect(find.text('Selected date Todo'), findsOneWidget);
    },
  );

  testWidgets('month navigation retains selection and Today restores both', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const CalendarPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);
    expect(find.text('Tuesday, June 2, 2026'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('calendar-today')));
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('Tuesday, June 2, 2026'), findsOneWidget);
  });

  testWidgets('calendar arrow keys move focus and selection by grid position', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    final List<LocalCalendarDate> routeUpdates = <LocalCalendarDate>[];
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: CalendarPage(onSelectedDateChanged: routeUpdates.add),
      ),
    );
    await tester.pumpAndSettle();
    final Finder juneSecond = find.byKey(
      const ValueKey<String>('calendar-day-2026-06-02'),
    );

    await tester.tap(juneSecond);
    await tester.pump();
    routeUpdates.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(find.text('Wednesday, June 3, 2026'), findsOneWidget);
    expect(routeUpdates.single.text, '2026-06-03');
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey<String>('calendar-day-2026-06-03')),
          )
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('focused calendar cells activate with Enter and Space', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const CalendarPage(),
      ),
    );
    await tester.pumpAndSettle();

    final Finder juneThird = find.byKey(
      const ValueKey<String>('calendar-day-2026-06-03'),
    );
    Focus.of(tester.element(juneThird)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Wednesday, June 3, 2026'), findsOneWidget);

    final Finder juneFourth = find.byKey(
      const ValueKey<String>('calendar-day-2026-06-04'),
    );
    Focus.of(tester.element(juneFourth)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Thursday, June 4, 2026'), findsOneWidget);
  });

  testWidgets(
    'selection, today, and Todo presence have visible non-color cues',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'todo', title: 'Has Todo'),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: const CalendarPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsWidgets);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('calendar-day-2026-06-03')),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check), findsWidgets);
    },
  );

  testWidgets('compact Korean calendar remains usable at 200-percent text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'todo', title: '텍스트가 긴 캘린더 할 일'),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);

    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        locale: const Locale('ko'),
        textScaler: const TextScaler.linear(2),
        child: const CalendarPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('2026년 6월'), findsOneWidget);
    expect(find.text('텍스트가 긴 캘린더 할 일'), findsOneWidget);
    expect(_findKeysWithPrefix('calendar-day-'), findsNWidgets(30));
  });

  testWidgets('calendar follows the responsive token matrix', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const List<({double width, Locale locale, TextScaler textScaler})> cases =
        <({double width, Locale locale, TextScaler textScaler})>[
          (width: 600, locale: Locale('ko'), textScaler: TextScaler.noScaling),
          (width: 920, locale: Locale('en'), textScaler: TextScaler.linear(2)),
          (width: 1280, locale: Locale('en'), textScaler: TextScaler.noScaling),
        ];

    for (final testCase in cases) {
      tester.view.physicalSize = Size(testCase.width, 800);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2, 10),
      );
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: TestTodoRepository(),
          dateClock: dateClock,
          locale: testCase.locale,
          textScaler: testCase.textScaler,
          child: const CalendarPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '${testCase.width}px');
      final SingleChildScrollView scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      final EdgeInsets padding = scroll.padding!.resolve(TextDirection.ltr);
      expect(
        padding.left,
        ClockRhythmLayout.horizontalInsetFor(testCase.width),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      dateClock.dispose();
    }
  });

  testWidgets('calendar scroll offset survives process restoration', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const CalendarPage(),
      ),
    );
    await tester.pumpAndSettle();
    final Finder page = find.byKey(
      const PageStorageKey<String>('calendar-page-scroll'),
    );
    await tester.drag(page, const Offset(0, -300));
    await tester.pumpAndSettle();
    final Finder verticalScrollable = find.descendant(
      of: page,
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(
      tester.state<ScrollableState>(verticalScrollable.first).position.pixels,
      greaterThan(0),
    );

    await tester.restartAndRestore();
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(verticalScrollable.first).position.pixels,
      greaterThan(0),
    );
  });
}

Finder _findKeysWithPrefix(String prefix) {
  return find.byWidgetPredicate((Widget widget) {
    final Key? key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}
