import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contexts/rhythm/presentation/support/fake_rhythm_actions.dart';
import '../contexts/todo/presentation/support/todo_presentation_test_support.dart';
import 'support/data_page_test_support.dart';

void main() {
  testWidgets('Rhythm actions expose labels for every tap target', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rhythmActionsProvider.overrideWithValue(FakeRhythmActions()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: LanguageLocaleMapper.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: RhythmControls()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('Rhythm start failures are exposed as a live status once shown', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeRhythmActions actions = FakeRhythmActions()
      ..startFailure = RhythmStartFailure.notificationPermission;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rhythmActionsProvider.overrideWithValue(actions)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: LanguageLocaleMapper.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: RhythmControls()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('start-rhythm')));
    await tester.pumpAndSettle();

    final SemanticsNode failure = tester.getSemantics(
      find.bySemanticsLabel(
        'Notification permission is required to start focus/rest delivery.',
      ),
    );
    expect(failure.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });

  testWidgets('Calendar tap targets expose localized semantic labels', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
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

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('Data actions expose localized semantic labels', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildDataPageTestApp());
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
