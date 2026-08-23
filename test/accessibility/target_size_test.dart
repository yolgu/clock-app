import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contexts/rhythm/presentation/support/fake_rhythm_actions.dart';
import '../contexts/todo/presentation/support/todo_presentation_test_support.dart';
import 'support/data_page_test_support.dart';

void main() {
  testWidgets('Rhythm actions meet Android 48dp target guidance', (
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
          home: const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: RhythmControls()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('Calendar actions and dates meet Android 48dp target guidance', (
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

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('Data actions meet Android 48dp target guidance', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildDataPageTestApp());
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });
}
