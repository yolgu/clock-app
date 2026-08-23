import 'package:clock_rhythm/main.dart' as app;
import 'package:clock_rhythm/shared/i18n/public.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'critical Android Todo journey survives destination changes and Back',
    (WidgetTester tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
      await app.main();

      const String todoTitle = 'E2E 사용자 여정';
      final Finder rhythmStatus = find.byKey(
        const ValueKey<String>('rhythm-status-value'),
      );
      await _pumpUntilFound(tester, rhythmStatus);
      final ({AppLocalizations copy, Locale locale}) localization =
          _readLocalization(tester, rhythmStatus);
      final AppLocalizations copy = localization.copy;
      final Finder clockPage = find.byKey(
        const PageStorageKey<String>('clock-page-scroll'),
      );
      final Finder todoInput = find.byKey(
        const ValueKey<String>('todo-create-title'),
      );

      expect(localization.locale.languageCode, 'ko');
      expect(tester.widget<Text>(rhythmStatus).data, copy.rhythmStatusIdle);
      expect(
        find.byKey(const ValueKey<String>('start-rhythm')),
        findsOneWidget,
      );

      await _scrollUntilVisible(
        tester: tester,
        scrollable: clockPage,
        target: todoInput,
      );
      expect(find.text(copy.todoListEmpty), findsOneWidget);

      await tester.tap(todoInput);
      await tester.enterText(todoInput, todoTitle);
      await tester.pump();
      final Finder addTodo = find.byKey(const ValueKey<String>('todo-add'));
      await tester.ensureVisible(addTodo);
      await tester.tap(addTodo);
      await _pumpUntilFound(tester, find.text(copy.messageTodoAdded));
      await _scrollUntilVisible(
        tester: tester,
        scrollable: clockPage,
        target: find.text(todoTitle),
      );

      final Finder createdTodo = find.descendant(
        of: find.byKey(const ValueKey<String>('today-todo-list')),
        matching: find.text(todoTitle),
      );
      expect(createdTodo, findsOneWidget);
      expect(find.text(copy.messageTodoAdded), findsOneWidget);

      await _selectDestination(tester, copy.navigationCalendar);
      final Finder calendarPage = find.byKey(
        const PageStorageKey<String>('calendar-page-scroll'),
      );
      await _pumpUntilFound(tester, calendarPage);
      await _scrollUntilVisible(
        tester: tester,
        scrollable: calendarPage,
        target: find.text(todoTitle),
      );
      expect(find.text(todoTitle), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _pumpUntilFound(tester, clockPage);
      await _scrollUntilVisible(
        tester: tester,
        scrollable: clockPage,
        target: find.text(todoTitle),
      );
      expect(find.text(todoTitle), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('calendar-board')),
        findsNothing,
      );
    },
  );
}

({AppLocalizations copy, Locale locale}) _readLocalization(
  WidgetTester tester,
  Finder anchor,
) {
  final BuildContext context = tester.element(anchor);
  return (
    copy: AppLocalizations.of(context),
    locale: Localizations.localeOf(context),
  );
}

Future<void> _selectDestination(WidgetTester tester, String label) async {
  final Finder destination = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  expect(destination, findsOneWidget);
  await tester.tap(destination);
  await tester.pump();
}

Future<void> _scrollUntilVisible({
  required WidgetTester tester,
  required Finder scrollable,
  required Finder target,
}) async {
  expect(scrollable, findsOneWidget);
  for (int attempt = 0; attempt < 40; attempt += 1) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pump();
      return;
    }
    await tester.drag(scrollable, const Offset(0, -100));
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Unable to reveal the expected E2E target.');
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder target) async {
  for (int attempt = 0; attempt < 300; attempt += 1) {
    if (target.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for the expected E2E target.');
}
