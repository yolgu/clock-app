import 'dart:async';

import 'package:clock_rhythm/app/clock_rhythm_app.dart';
import 'package:clock_rhythm/app/navigation/app_router.dart';
import 'package:clock_rhythm/app/platform_presentation_profile.dart';
import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/todo_presentation_test_support.dart';

void main() {
  testWidgets(
    'creation controls align right below the full-width input in Clock and Calendar',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final TestTodoDateClock clock = TestTodoDateClock(DateTime(2026, 6, 2));
      addTearDown(clock.dispose);
      for (final double width in <double>[360, 390, 720, 1280]) {
        for (final double scale in <double>[1, 2]) {
          for (final Locale locale in <Locale>[
            const Locale('ko'),
            const Locale('en'),
          ]) {
            for (final bool calendar in <bool>[false, true]) {
              tester.view.physicalSize = Size(width, 1200);
              await tester.pumpWidget(
                buildTodoTestApp(
                  repository: TestTodoRepository(),
                  dateClock: clock,
                  locale: locale,
                  textScaler: TextScaler.linear(scale),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: calendar
                          ? TodoEditor.forDate(
                              date: LocalCalendarDate.parse('2026-06-02'),
                            )
                          : TodoEditor.today(
                              date: LocalCalendarDate.parse('2026-06-02'),
                            ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final Rect editor = tester.getRect(find.byType(TodoEditor));
              final Rect input = tester.getRect(
                find.byKey(const ValueKey<String>('todo-create-title')),
              );
              final Rect add = tester.getRect(
                find.byKey(const ValueKey<String>('todo-add')),
              );
              final Finder time = find.byKey(
                const ValueKey<String>('todo-add-time'),
              );
              final Rect timeGroup = tester.getRect(
                find
                    .ancestor(of: time, matching: find.byType(IntrinsicWidth))
                    .first,
              );
              final Rect timeButton = tester.getRect(time);
              expect(input.left, editor.left);
              expect(input.right, editor.right);
              expect(timeGroup.top, greaterThanOrEqualTo(input.bottom + 8));
              expect(add.top, greaterThanOrEqualTo(input.bottom + 8));
              expect(add.right, closeTo(editor.right, 0.01));
              if (timeGroup.width + 8 + add.width <= editor.width) {
                expect(
                  timeGroup.center.dy,
                  closeTo(add.center.dy, 0.01),
                  reason:
                      '$width / $scale / $locale / time $timeGroup / add $add',
                );
                expect(timeGroup.right + 8, closeTo(add.left, 0.01));
                expect(timeButton.right + 8, closeTo(add.left, 0.01));
              } else {
                expect(timeGroup.right, closeTo(editor.right, 0.01));
                expect(timeButton.right, closeTo(editor.right, 0.01));
              }
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            }
          }
        }
      }
    },
  );

  testWidgets('Todo title and detail actions have accessible tap targets', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'one', title: 'Task', time: '09:30'),
    ]);
    await _pumpToday(tester, repository, platform: TargetPlatform.android);
    try {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'inline editing keeps its bounds across locales, widths and text scales',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final double width in <double>[360, 390, 720, 1280]) {
        for (final double scale in <double>[1, 2]) {
          for (final Locale locale in <Locale>[
            const Locale('ko'),
            const Locale('en'),
          ]) {
            tester.view.physicalSize = Size(width, 1200);
            final TestTodoRepository repository = TestTodoRepository(<Todo>[
              createTestTodo(
                id: 'one',
                title: locale.languageCode == 'ko'
                    ? '여러 줄로 표시되는 길이가 긴 할 일 제목입니다'
                    : 'A longer title that wraps across several lines',
              ),
            ]);
            final TestTodoDateClock clock = TestTodoDateClock(
              DateTime(2026, 6, 2),
            );
            await tester.pumpWidget(
              buildTodoTestApp(
                repository: repository,
                dateClock: clock,
                locale: locale,
                textScaler: TextScaler.linear(scale),
                child: const SingleChildScrollView(child: TodayTodoPanel()),
              ),
            );
            await tester.pumpAndSettle();
            final Finder row = find.byKey(
              const ValueKey<String>('todo-row-one'),
            );
            final Finder action = find.byKey(
              const ValueKey<String>('todo-edit-one'),
            );
            final Rect before = tester.getRect(row);
            final Rect actionBefore = tester.getRect(action);
            await tester.tap(
              find.byKey(const ValueKey<String>('todo-title-one')),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getSize(row),
              before.size,
              reason: '$width / $scale / $locale',
            );
            // A real mobile keyboard may scroll the page to reveal the caret.
            expect(
              tester.getTopLeft(action) - tester.getTopLeft(row),
              actionBefore.topLeft - before.topLeft,
            );
            expect(tester.takeException(), isNull);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpWidget(const SizedBox.shrink());
            clock.dispose();
          }
        }
      }
    },
  );

  testWidgets(
    'a delayed creation blocks duplicate Enter and keeps failed input',
    (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();
      final TestTodoRepository repository = TestTodoRepository()
        ..mutationGate = gate
        ..failMutations = true;
      await _pumpToday(tester, repository);
      final Finder field = find.byKey(
        const ValueKey<String>('todo-create-title'),
      );
      await tester.enterText(field, 'Keep my draft');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repository.mutateCalls, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(_editable(tester, field).controller.text, 'Keep my draft');
      expect(repository.todos, isEmpty);
    },
  );

  testWidgets(
    'moving a Todo in details returns focus to the current composer',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'one', title: 'Original'),
      ]);
      await _pumpToday(tester, repository);
      await tester.tap(find.byKey(const ValueKey<String>('todo-edit-one')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('todo-edit-date')));
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byType(DatePickerDialog)),
      ).pop(DateTime(2026, 6, 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('todo-save')));
      await tester.pumpAndSettle();
      expect(repository.todos.single.date.text, '2026-06-03');
      expect(find.byType(Dialog), findsNothing);
      expect(
        _editable(
          tester,
          find.byKey(const ValueKey<String>('todo-create-title')),
        ).focusNode.hasFocus,
        isTrue,
      );
    },
  );

  testWidgets('details cannot close during save and remain open on failure', (
    WidgetTester tester,
  ) async {
    final Completer<void> gate = Completer<void>();
    final TestTodoRepository repository =
        TestTodoRepository(<Todo>[createTestTodo(id: 'one', title: 'Original')])
          ..mutationGate = gate
          ..failMutations = true;
    await _pumpToday(tester, repository);
    await tester.tap(find.byKey(const ValueKey<String>('todo-edit-one')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-edit-title')),
      'Retry details',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('todo-save')));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      _editable(
        tester,
        find.byKey(const ValueKey<String>('todo-edit-title')),
      ).controller.text,
      'Retry details',
    );
    expect(repository.todos.single.title.text, 'Original');
  });

  testWidgets(
    'inline rename saves once and preserves date, time and completion',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(
          id: 'one',
          title: 'Original',
          time: '09:30',
          completed: true,
        ),
      ]);
      await _pumpToday(tester, repository);
      await tester.tap(find.byKey(const ValueKey<String>('todo-title-one')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-inline-title-one')),
        '  Renamed  ',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(repository.mutateCalls, 1);
      expect(repository.todos.single.title.text, 'Renamed');
      expect(repository.todos.single.time?.text, '09:30');
      expect(repository.todos.single.date.text, '2026-06-02');
      expect(repository.todos.single.completionGroup.isCompleted, isTrue);
    },
  );

  testWidgets('blur saves the title without stealing the next input focus', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'one', title: 'Original'),
    ]);
    await _pumpToday(tester, repository, extraInput: true);
    await tester.tap(find.byKey(const ValueKey<String>('todo-title-one')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-inline-title-one')),
      'Renamed',
    );
    final Finder outside = find.byKey(const ValueKey<String>('outside-input'));
    await tester.tap(outside);
    await tester.pumpAndSettle();
    expect(repository.todos.single.title.text, 'Renamed');
    expect(_editable(tester, outside).focusNode.hasFocus, isTrue);
  });

  testWidgets(
    'invalid and failed inline edits retain their draft without moving the next row',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'one', title: 'Original'),
        createTestTodo(id: 'two', title: 'Next', displayOrder: 1),
      ]);
      await _pumpToday(tester, repository);
      final Finder next = find.byKey(const ValueKey<String>('todo-row-two'));
      final Rect before = tester.getRect(next);
      await tester.tap(find.byKey(const ValueKey<String>('todo-title-one')));
      await tester.pumpAndSettle();
      final Finder input = find.byKey(
        const ValueKey<String>('todo-inline-title-one'),
      );
      await tester.enterText(input, '');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(repository.mutateCalls, 0);
      expect(find.text('Enter a Todo.'), findsOneWidget);
      expect(tester.getRect(next), before);
      repository.failMutations = true;
      await tester.enterText(input, 'Retry this title');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_editable(tester, input).controller.text, 'Retry this title');
      expect(repository.todos.first.title.text, 'Original');
      expect(tester.getRect(next), before);
      repository.failMutations = false;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(repository.todos.first.title.text, 'Retry this title');
    },
  );

  testWidgets('Enter while composing Korean does not rename the Todo', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'one', title: 'Original'),
    ]);
    await _pumpToday(tester, repository);
    await tester.tap(find.byKey(const ValueKey<String>('todo-title-one')));
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '할',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(repository.mutateCalls, 0);
    expect(
      find.byKey(const ValueKey<String>('todo-inline-title-one')),
      findsOneWidget,
    );
  });

  testWidgets('a row command waits for a pending rename', (
    WidgetTester tester,
  ) async {
    final Completer<void> gate = Completer<void>();
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'one', title: 'Original'),
    ])..mutationGate = gate;
    await _pumpToday(tester, repository);
    await tester.tap(find.byKey(const ValueKey<String>('todo-title-one')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('todo-inline-title-one')),
      'Renamed',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(repository.mutateCalls, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.mutateCalls, 2);
    expect(repository.todos.single.title.text, 'Renamed');
    expect(repository.todos.single.completionGroup.isCompleted, isTrue);
  });

  testWidgets(
    'creation does not take focus back from a different input during a delayed save',
    (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();
      final TestTodoRepository repository = TestTodoRepository()
        ..mutationGate = gate;
      await _pumpToday(tester, repository, extraInput: true);
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-create-title')),
        'Task',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final Finder outside = find.byKey(
        const ValueKey<String>('outside-input'),
      );
      await tester.tap(outside);
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();
      expect(_editable(tester, outside).focusNode.hasFocus, isTrue);
      expect(repository.todos.single.title.text, 'Task');
    },
  );

  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.windows,
    TargetPlatform.android,
  ]) {
    testWidgets(
      '$platform details preserve the background row and return focus on cancel',
      (WidgetTester tester) async {
        final TestTodoRepository repository = TestTodoRepository(<Todo>[
          createTestTodo(id: 'one', title: 'Original'),
        ]);
        await _pumpToday(tester, repository, platform: platform);
        final Finder row = find.byKey(const ValueKey<String>('todo-row-one'));
        final Rect before = tester.getRect(row);
        final Finder button = find.byKey(
          const ValueKey<String>('todo-edit-one'),
        );
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
          find.byType(
            platform == TargetPlatform.windows ? Dialog : BottomSheet,
          ),
          findsOneWidget,
        );
        expect(tester.getRect(row), before);
        await tester.enterText(
          find.byKey(const ValueKey<String>('todo-edit-title')),
          'Discarded',
        );
        final Finder cancel = find.byKey(const ValueKey<String>('todo-cancel'));
        await tester.ensureVisible(cancel);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(repository.todos.single.title.text, 'Original');
        expect(tester.widget<IconButton>(button).focusNode!.hasFocus, isTrue);
        expect(tester.getRect(row), before);
      },
    );
  }

  testWidgets(
    'Android Back cancels inline editing before returning Calendar to Clock',
    (WidgetTester tester) async {
      final TestTodoRepository repository = TestTodoRepository(<Todo>[
        createTestTodo(id: 'one', title: 'Original'),
      ]);
      final TestTodoDateClock clock = TestTodoDateClock(DateTime(2026, 6, 2));
      addTearDown(clock.dispose);
      final ClockRhythmRouter router = ClockRhythmRouter(
        profile: PlatformPresentationProfile.android,
        initialLocation: '/calendar',
        pages: AppDestinationPages(
          clock: (_) => const Text('Clock'),
          calendar: (_, _) =>
              const SingleChildScrollView(child: TodayTodoPanel()),
          data: (_) => const SizedBox.shrink(),
          theme: (_) => const SizedBox.shrink(),
          settings: (_) => const SizedBox.shrink(),
        ),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todoPresentationDependenciesProvider.overrideWithValue(
              createTodoPresentationDependencies(repository: repository),
            ),
            todoDateClockProvider.overrideWithValue(clock),
          ],
          child: ClockRhythmApp(
            router: router.router,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('todo-title-one')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('todo-inline-title-one')),
        'Cancel me',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(repository.todos.single.title.text, 'Original');
      expect(router.router.state.uri.path, '/calendar');
      expect(
        find.byKey(const ValueKey<String>('todo-inline-title-one')),
        findsNothing,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.router.state.uri.path, '/clock');
    },
  );

  for (final bool calendar in <bool>[false, true]) {
    for (final bool enter in <bool>[false, true]) {
      testWidgets(
        '${calendar ? 'Calendar' : 'Clock'} restores creation focus after ${enter ? 'Enter' : 'Add'}',
        (WidgetTester tester) async {
          final TestTodoRepository repository = TestTodoRepository();
          final TestTodoDateClock clock = TestTodoDateClock(
            DateTime(2026, 6, 2),
          );
          addTearDown(clock.dispose);
          await tester.pumpWidget(
            buildTodoTestApp(
              repository: repository,
              dateClock: clock,
              child: SingleChildScrollView(
                child: calendar
                    ? TodoEditor.forDate(
                        date: LocalCalendarDate.parse('2026-06-02'),
                      )
                    : const TodayTodoPanel(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final Finder title = find.byKey(
            const ValueKey<String>('todo-create-title'),
          );
          await tester.enterText(title, 'First task');
          await tester.pump();
          if (enter) {
            await tester.testTextInput.receiveAction(TextInputAction.done);
          } else {
            await tester.tap(find.byKey(const ValueKey<String>('todo-add')));
          }
          await tester.pumpAndSettle();
          final EditableText editable = tester.widget<EditableText>(
            find.descendant(of: title, matching: find.byType(EditableText)),
          );
          expect(repository.todos.single.title.text, 'First task');
          expect(editable.controller.text, isEmpty);
          expect(editable.focusNode.hasFocus, isTrue);
          tester.testTextInput.enterText('Second task');
          await tester.pump();
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(repository.todos, hasLength(2));
        },
      );
    }
  }

  testWidgets('title editing preserves row bounds and Escape cancels', (
    WidgetTester tester,
  ) async {
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'one', title: 'Original title'),
      createTestTodo(id: 'two', title: 'Second title', displayOrder: 1),
    ]);
    final TestTodoDateClock clock = TestTodoDateClock(DateTime(2026, 6, 2));
    addTearDown(clock.dispose);
    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: clock,
        child: const SingleChildScrollView(child: TodayTodoPanel()),
      ),
    );
    await tester.pumpAndSettle();
    final Finder row = find.byKey(const ValueKey<String>('todo-row-one'));
    final Finder next = find.byKey(const ValueKey<String>('todo-row-two'));
    final Rect before = tester.getRect(row);
    final Rect nextBefore = tester.getRect(next);
    await tester.tap(find.byKey(const ValueKey<String>('todo-title-one')));
    await tester.pumpAndSettle();
    final Finder input = find.byKey(
      const ValueKey<String>('todo-inline-title-one'),
    );
    expect(input, findsOneWidget);
    await tester.enterText(
      input,
      'A much longer draft title that must not expand this row while typing',
    );
    await tester.pump();
    expect(tester.getRect(row), before);
    expect(tester.getRect(next), nextBefore);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repository.todos.first.title.text, 'Original title');
    expect(repository.mutateCalls, 0);
    expect(tester.getRect(row), before);
  });
}

EditableText _editable(WidgetTester tester, Finder field) {
  return tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
}

Future<void> _pumpToday(
  WidgetTester tester,
  TestTodoRepository repository, {
  TargetPlatform platform = TargetPlatform.windows,
  bool extraInput = false,
}) async {
  final TestTodoDateClock clock = TestTodoDateClock(DateTime(2026, 6, 2));
  addTearDown(clock.dispose);
  await tester.pumpWidget(
    buildTodoTestApp(
      repository: repository,
      dateClock: clock,
      theme: ClockRhythmTheme.build(
        ThemeCatalog.resolve(ThemePreference.current),
        platform: platform,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const TodayTodoPanel(),
            if (extraInput)
              const TextField(key: ValueKey<String>('outside-input')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
