import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contexts/todo/presentation/support/todo_presentation_test_support.dart';

void main() {
  testWidgets('compact Korean calendar at 200-percent text', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(360, 800));
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'open', title: '길어도 읽을 수 있는 오늘의 할 일', time: '08:30'),
      createTestTodo(
        id: 'done',
        title: '완료한 할 일',
        displayOrder: 1,
        completed: true,
      ),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(
      DateTime(2026, 6, 2, 10),
    );
    addTearDown(dateClock.dispose);

    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        locale: const Locale('ko'),
        textScaler: const TextScaler.linear(2),
        theme: ClockRhythmTheme.build(
          ThemeCatalog.resolve(ThemePreference.current),
        ),
        child: const RepaintBoundary(
          key: ValueKey<String>('golden-surface'),
          child: CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('golden-surface')),
      matchesGoldenFile('baselines/compact_calendar_ko_200.png'),
    );
  });

  testWidgets('wide English calendar in Neon Dusk', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'open', title: 'Prepare release evidence'),
      createTestTodo(
        id: 'done',
        title: 'Verify portable backup',
        displayOrder: 1,
        completed: true,
      ),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(
      DateTime(2026, 6, 2, 10),
    );
    addTearDown(dateClock.dispose);

    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        theme: ClockRhythmTheme.build(
          ThemeCatalog.resolve(ThemePreference.monokaiPro),
        ),
        child: const RepaintBoundary(
          key: ValueKey<String>('golden-surface'),
          child: CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('golden-surface')),
      matchesGoldenFile('baselines/wide_calendar_en_neon_dusk.png'),
    );
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
