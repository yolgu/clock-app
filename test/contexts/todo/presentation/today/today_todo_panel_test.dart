import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/todo_presentation_test_support.dart';

void main() {
  testWidgets('LB-019 shows a failed Todo command in the owning Today panel', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository()
      ..failMutations = true;
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();
    final Finder panel = find.byKey(const ValueKey<String>('today-todo-panel'));
    final String failureMessage = AppLocalizations.of(
      tester.element(panel),
    ).failureTodoAction;

    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-create-title')),
      'Report',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('todo-add')));
    await tester.pumpAndSettle();

    expect(repository.todos, isEmpty);
    expect(repository.mutateCalls, 1);
    expect(find.text(failureMessage), findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text(failureMessage)),
      findsOneWidget,
    );
  });

  testWidgets('LB-020 blocks an empty Today title before creating a Todo', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();
    final Finder title = find.byKey(
      const ValueKey<String>('todo-create-title'),
    );
    final Finder add = find.byKey(const ValueKey<String>('todo-add'));

    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    expect(find.text('Enter a Todo.'), findsNothing);

    await tester.enterText(title, '   ');
    await tester.pump();

    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    expect(find.text('Enter a Todo.'), findsOneWidget);
    expect(repository.mutateCalls, 0);
  });

  testWidgets(
    'LB-021 reveals the Today title error only after edited text is cleared',
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
          child: const SingleChildScrollView(child: TodayTodoPanel()),
        ),
      );
      await tester.pumpAndSettle();
      final Finder title = find.byKey(
        const ValueKey<String>('todo-create-title'),
      );

      expect(find.text('Enter a Todo.'), findsNothing);
      await tester.enterText(title, 'Report');
      await tester.pump();
      expect(find.text('Enter a Todo.'), findsNothing);

      await tester.enterText(title, '');
      await tester.pump();

      expect(find.text('Enter a Todo.'), findsOneWidget);
      expect(repository.mutateCalls, 0);
    },
  );

  testWidgets('adds a trimmed Todo and keeps optional time display quiet', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'timed', title: 'Timed Todo', time: '08:15'),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(
      DateTime(2026, 6, 2, 10),
    );
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-create-title')),
      '  Report  ',
    );
    await tester.pump();
    final Finder addButton = find.byKey(const ValueKey<String>('todo-add'));
    expect(tester.widget<FilledButton>(addButton).onPressed, isNotNull);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(
      repository.todos.map((Todo todo) => todo.title.text),
      contains('Report'),
    );
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('08:15'), findsOneWidget);
    expect(find.text('--:--'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(repository.todos, hasLength(2));
  });

  testWidgets('shows a grapheme counter at 120 and validates the 160 limit', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();
    final Finder title = find.byKey(
      const ValueKey<String>('todo-create-title'),
    );

    await tester.enterText(title, List<String>.filled(120, '가').join());
    await tester.pump();
    expect(find.text('120/160'), findsOneWidget);

    await tester.enterText(title, List<String>.filled(161, '🙂').join());
    await tester.pump();
    expect(find.text('161/160'), findsOneWidget);
    expect(find.text('Todos must be 160 characters or fewer.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey<String>('todo-add')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'completes, reopens, and permanently deletes without transient UI',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'todo-1', title: 'One Todo'),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: const SingleChildScrollView(child: TodayTodoPanel()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(repository.todos.single.completionGroup.isCompleted, isTrue);
      expect(find.text('Completed'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(repository.todos.single.completionGroup.isCompleted, isFalse);

      await tester.tap(
        find.byKey(const ValueKey<String>('todo-delete-todo-1')),
      );
      await tester.pumpAndSettle();
      expect(repository.todos, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'LB-026 explicit Save and Cancel buttons commit or discard editor drafts',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'todo-1', title: 'Before'),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: const SingleChildScrollView(child: TodayTodoPanel()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('todo-edit-todo-1')));
      await tester.pump();
      final Finder title = find.byKey(
        const ValueKey<String>('todo-edit-title'),
      );
      final Finder save = find.byKey(const ValueKey<String>('todo-save'));
      final Finder cancel = find.byKey(const ValueKey<String>('todo-cancel'));
      expect(save, findsOneWidget);
      expect(cancel, findsOneWidget);

      await tester.enterText(title, 'Discarded');
      await tester.tap(cancel);
      await tester.pump();
      expect(repository.todos.single.title.text, 'Before');
      expect(repository.mutateCalls, 0);

      await tester.tap(find.byKey(const ValueKey<String>('todo-edit-todo-1')));
      await tester.pump();
      await tester.enterText(title, 'After');
      final int mutationsBeforeSave = repository.mutateCalls;

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(repository.mutateCalls - mutationsBeforeSave, 1);
      expect(repository.todos.single.title.text, 'After');
      expect(find.text('After'), findsOneWidget);
      expect(title, findsNothing);
    },
  );

  testWidgets('LB-026 Escape cancels an edit without sending UpdateTodo', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'todo-1', title: 'Before'),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-todo-1')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-edit-title')),
      'Cancelled',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('todo-edit-title')), findsNothing);
    expect(repository.todos.single.title.text, 'Before');
    expect(repository.mutateCalls, 0);
  });

  testWidgets('optional time uses the localized 24-hour picker and can clear', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('todo-add-time')));
    await tester.pumpAndSettle();
    final Finder picker = find.byType(TimePickerDialog);
    expect(picker, findsOneWidget);
    expect(MediaQuery.of(tester.element(picker)).alwaysUse24HourFormat, isTrue);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final Finder editTime = find.byKey(
      const ValueKey<String>('todo-edit-time'),
    );
    expect(editTime, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data!),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('todo-clear-time')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('todo-add-time')), findsOneWidget);
  });

  testWidgets('LB-025 normalizes picker time when adding and editing a Todo', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository();
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-create-title')),
      'Timed Todo',
    );
    await tester.tap(find.byKey(const ValueKey<String>('todo-add-time')));
    await _enterPickerTime(tester, hour: '14', minute: '30');
    await tester.tap(find.byKey(const ValueKey<String>('todo-add')));
    await tester.pumpAndSettle();

    expect(repository.todos.single.time?.text, '14:30');
    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-created-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-time')));
    await _enterPickerTime(tester, hour: '9', minute: '05');
    await tester.tap(find.byKey(const ValueKey<String>('todo-save')));
    await tester.pumpAndSettle();

    expect(repository.todos.single.time?.text, '09:05');
  });

  testWidgets('LB-027 blocks an invalid edit before UpdateTodo is called', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'todo-1', title: 'Before'),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-todo-1')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-edit-title')),
      '',
    );
    await tester.pump();

    final Finder save = find.byKey(const ValueKey<String>('todo-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(find.text('Enter a Todo.'), findsOneWidget);
    expect(repository.mutateCalls, 0);
    expect(repository.todos.single.title.text, 'Before');
  });

  testWidgets(
    'exposes localized semantic moves and keyboard arrows per group',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'a', title: 'A', displayOrder: 0),
        createTestTodo(id: 'b', title: 'B', displayOrder: 1),
        createTestTodo(id: 'c', title: 'C', displayOrder: 2),
        createTestTodo(id: 'done', title: 'Done', completed: true),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: const SingleChildScrollView(child: TodayTodoPanel()),
        ),
      );
      await tester.pumpAndSettle();
      final Finder reorderB = find.bySemanticsLabel('Reorder B');
      final SemanticsData reorderData = tester
          .getSemantics(find.text('B'))
          .getSemanticsData();
      final List<String?> actionLabels = reorderData.customSemanticsActionIds!
          .map(
            (int identifier) =>
                CustomSemanticsAction.getAction(identifier)?.label,
          )
          .toList(growable: false);
      expect(actionLabels, containsAll(<String>['Move up', 'Move down']));

      await tester.tap(reorderB);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      final List<TodoSnapshot> ordered = await ListTodosForDate(
        repository: repository,
      ).execute('2026-06-02');
      expect(ordered.map((TodoSnapshot todo) => todo.id), <String>[
        'b',
        'a',
        'c',
        'done',
      ]);
      semantics.dispose();
    },
  );

  testWidgets(
    'LB-030 drag handles reorder without rendering separate move buttons',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'a', title: 'A', displayOrder: 0),
        createTestTodo(id: 'b', title: 'B', displayOrder: 1),
        createTestTodo(id: 'c', title: 'C', displayOrder: 2),
      ]);
      final TestTodoDateClock dateClock = TestTodoDateClock(
        DateTime(2026, 6, 2),
      );
      addTearDown(dateClock.dispose);
      await tester.pumpWidget(
        buildTodoTestApp(
          repository: repository,
          dateClock: dateClock,
          child: const SingleChildScrollView(child: TodayTodoPanel()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
      expect(find.widgetWithIcon(IconButton, Icons.arrow_upward), findsNothing);
      expect(
        find.widgetWithIcon(IconButton, Icons.arrow_downward),
        findsNothing,
      );

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 160));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      final List<TodoSnapshot> ordered = await ListTodosForDate(
        repository: repository,
      ).execute('2026-06-02');
      expect(ordered.map((TodoSnapshot todo) => todo.id), <String>[
        'b',
        'a',
        'c',
      ]);
      expect(find.byType(ReorderableDragStartListener), findsNWidgets(3));
    },
  );

  testWidgets('uses a compact 200-percent text layout without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(
        id: 'long',
        title: 'A long Todo title that wraps instead of losing its actions',
        time: '18:30',
      ),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(dateClock.dispose);

    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        textScaler: const TextScaler.linear(2),
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('todo-edit-long')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('todo-delete-long')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('todo-delete-long')))
          .height,
      greaterThanOrEqualTo(48),
    );
  });
}

Future<void> _enterPickerTime(
  WidgetTester tester, {
  required String hour,
  required String minute,
}) async {
  await tester.pumpAndSettle();
  final Finder picker = find.byType(TimePickerDialog);
  expect(picker, findsOneWidget);
  expect(MediaQuery.of(tester.element(picker)).alwaysUse24HourFormat, isTrue);

  await tester.tap(
    find.descendant(of: picker, matching: find.byIcon(Icons.keyboard_outlined)),
  );
  await tester.pumpAndSettle();
  final Finder fields = find.descendant(
    of: picker,
    matching: find.byType(TextFormField),
  );
  expect(fields, findsNWidgets(2));

  await tester.enterText(fields.at(0), hour);
  await tester.enterText(fields.at(1), minute);
  await tester.tap(
    find.descendant(
      of: picker,
      matching: find.widgetWithText(TextButton, 'OK'),
    ),
  );
  await tester.pumpAndSettle();
}
