import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/presentation/todo_time_dialog.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ValueKey<String> hourField = ValueKey<String>('todo-time-hour');
  const ValueKey<String> minuteField = ValueKey<String>('todo-time-minute');
  const ValueKey<String> confirm = ValueKey<String>('todo-time-confirm');

  /// Opens the dialog and returns where its outcome lands: an empty list
  /// while it is open, then the single value it completed with.
  Future<List<ClockTimeParts?>> openDialog(
    WidgetTester tester, {
    required ClockTimeParts initialTime,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    final List<ClockTimeParts?> outcomes = <ClockTimeParts?>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ClockRhythmTheme.build(
          ThemeCatalog.resolve(ThemePreference.current),
          platform: TargetPlatform.windows,
        ),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () async {
                  outcomes.add(
                    await showTodoTimeDialog(
                      context: context,
                      initialTime: initialTime,
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return outcomes;
  }

  String textOf(WidgetTester tester, ValueKey<String> field) {
    return tester.widget<TextField>(find.byKey(field)).controller!.text;
  }

  testWidgets('confirming returns the typed 24-hour time', (
    WidgetTester tester,
  ) async {
    final List<ClockTimeParts?> outcomes = await openDialog(
      tester,
      initialTime: (hour: 19, minute: 39),
    );

    expect(find.text('Edit Todo time'), findsOneWidget);
    expect(textOf(tester, hourField), '19');
    expect(textOf(tester, minuteField), '39');

    await tester.enterText(find.byKey(hourField), '7');
    await tester.enterText(find.byKey(minuteField), '05');
    await tester.tap(find.byKey(confirm));
    await tester.pumpAndSettle();

    expect(outcomes, <ClockTimeParts?>[(hour: 7, minute: 5)]);
  });

  testWidgets('the hour steps by one and wraps past midnight', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, initialTime: (hour: 23, minute: 0));

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
    await openDialog(tester, initialTime: (hour: 19, minute: 39));
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
    await openDialog(tester, initialTime: (hour: 9, minute: 30));

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
    final List<ClockTimeParts?> outcomes = await openDialog(
      tester,
      initialTime: (hour: 19, minute: 39),
    );
    const ValueKey<String> invalid = ValueKey<String>('todo-time-invalid');
    expect(find.byKey(invalid), findsNothing);

    await tester.enterText(find.byKey(hourField), '24');
    await tester.pump();
    expect(find.byKey(invalid), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(confirm)).onPressed, isNull);

    await tester.enterText(find.byKey(hourField), '');
    await tester.pump();
    expect(find.byKey(invalid), findsOneWidget);

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
    expect(outcomes, <ClockTimeParts?>[(hour: 23, minute: 59)]);
  });

  testWidgets('cancelling returns no time', (WidgetTester tester) async {
    final List<ClockTimeParts?> outcomes = await openDialog(
      tester,
      initialTime: (hour: 19, minute: 39),
    );

    await tester.enterText(find.byKey(hourField), '8');
    await tester.tap(find.byKey(const ValueKey<String>('todo-time-cancel')));
    await tester.pumpAndSettle();

    expect(outcomes, <ClockTimeParts?>[null]);
  });

  testWidgets('a narrow window with doubled text keeps every control usable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openDialog(
      tester,
      initialTime: (hour: 19, minute: 39),
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
  });
}
