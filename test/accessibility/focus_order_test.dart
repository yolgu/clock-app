import 'package:clock_rhythm/app/navigation/app_routes.dart';
import 'package:clock_rhythm/app/presentation/app_navigation_copy.dart';
import 'package:clock_rhythm/app/presentation/app_shortcuts.dart';
import 'package:clock_rhythm/app/presentation/windows_top_navigation.dart';
import 'package:clock_rhythm/features/data_transfer/application/backup_preview.dart';
import 'package:clock_rhythm/features/data_transfer/presentation/backup_import_preview_dialog.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ctrl+1 through Ctrl+4 map to the four main destinations', (
    WidgetTester tester,
  ) async {
    final List<int> selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppShortcuts(
            onDestinationSelected: selections.add,
            child: const TextField(autofocus: true),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final LogicalKeyboardKey digit in <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ]) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(digit);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    expect(selections, <int>[0, 1, 2, 3]);
  });

  testWidgets('Windows segmented navigation responds to arrow keys', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_NavigationHarnessState> key =
        GlobalKey<_NavigationHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(body: _NavigationHarness(key: key)),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(key.currentState!.selectedIndex, MainDestination.calendar.index);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(key.currentState!.selectedIndex, MainDestination.clock.index);
  });

  testWidgets('Escape cancels a prepared import before confirmation', (
    WidgetTester tester,
  ) async {
    bool cancelled = false;
    await tester.pumpWidget(
      _localizedApp(
        BackupImportPreviewDialog(
          preview: _preview,
          confirming: false,
          onCancel: () {
            cancelled = true;
          },
          onConfirm: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(cancelled, isTrue);
  });
}

const AppNavigationCopy _navigationCopy = AppNavigationCopy(
  clockLabel: 'Clock',
  navigationSemanticsLabel: 'App destinations',
  calendarLabel: 'Calendar',
  dataLabel: 'Data',
  themeLabel: 'Theme',
  routeErrorTitle: 'Cannot open page',
  malformedCalendarDateMessage: 'Invalid calendar date',
  unknownLocationMessage: 'Unknown page',
  backToClockLabel: 'Back to Clock',
);

final BackupPreview _preview = BackupPreview(
  exportedAt: DateTime.utc(2026, 8, 23),
  todoCount: 2,
  completedTodoCount: 1,
  earliestTodoDate: '2026-08-23',
  latestTodoDate: '2026-08-24',
  focusMinutes: 50,
  restMinutes: 10,
  dailyStart: '05:00',
  dailyEnd: '18:00',
  languageId: 'en',
  themeId: 'current',
  autoStartEnabled: false,
  autoStartWillChange: false,
  customSoundWasSanitized: false,
);

Widget _localizedApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: LanguageLocaleMapper.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

final class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness({super.key});

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

final class _NavigationHarnessState extends State<_NavigationHarness> {
  int selectedIndex = MainDestination.clock.index;

  @override
  Widget build(BuildContext context) {
    return WindowsTopNavigation(
      selectedIndex: selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          selectedIndex = index;
        });
      },
      copy: _navigationCopy,
    );
  }
}
