import 'package:clock_rhythm/app/navigation/app_routes.dart';
import 'package:clock_rhythm/app/presentation/app_navigation_copy.dart';
import 'package:clock_rhythm/app/presentation/side_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists every destination with its shortcut hint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(shortcutModifierLabel: 'Ctrl+'));

    for (final MainDestination destination in MainDestination.values) {
      expect(
        find.byKey(ValueKey<String>('side-destination-${destination.name}')),
        findsOneWidget,
      );
      expect(find.text('Ctrl+${destination.index + 1}'), findsOneWidget);
    }
    expect(find.text('Clock Rhythm'), findsOneWidget);
  });

  testWidgets('hides shortcut hints when no keyboard is expected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(shortcutModifierLabel: null));

    expect(find.textContaining('Ctrl+'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('exposes button and selected semantics for each destination', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(_harness(shortcutModifierLabel: 'Ctrl+'));

    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('side-destination-clock')),
      ),
      matchesSemantics(
        label: 'Clock',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('side-destination-data')),
      ),
      matchesSemantics(
        label: 'Data',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('moves selection and focus with arrows without wrapping', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_HarnessState> key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_harness(key: key, shortcutModifierLabel: null));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(key.currentState!.selectedIndex, MainDestination.clock.index);

    for (int step = 0; step < MainDestination.values.length + 1; step += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    expect(key.currentState!.selectedIndex, MainDestination.settings.index);
  });

  testWidgets('clicking a destination reports its index', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_HarnessState> key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_harness(key: key, shortcutModifierLabel: null));

    await tester.tap(find.text('Theme'));
    await tester.pump();

    expect(key.currentState!.selectedIndex, MainDestination.theme.index);
  });

  testWidgets('keeps every destination tappable at 150-percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_harness(shortcutModifierLabel: 'Ctrl+'));

    for (final MainDestination destination in MainDestination.values) {
      final Size size = tester.getSize(
        find.byKey(ValueKey<String>('side-destination-${destination.name}')),
      );
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });
}

Widget _harness({Key? key, required String? shortcutModifierLabel}) {
  return MaterialApp(
    theme: ThemeData(platform: TargetPlatform.windows),
    home: Scaffold(
      body: Row(
        children: <Widget>[
          _Harness(key: key, shortcutModifierLabel: shortcutModifierLabel),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    ),
  );
}

final class _Harness extends StatefulWidget {
  const _Harness({required this.shortcutModifierLabel, super.key});

  final String? shortcutModifierLabel;

  @override
  State<_Harness> createState() => _HarnessState();
}

final class _HarnessState extends State<_Harness> {
  int selectedIndex = MainDestination.clock.index;

  @override
  Widget build(BuildContext context) {
    return SideNavigation(
      selectedIndex: selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          selectedIndex = index;
        });
      },
      copy: _copy,
      shortcutModifierLabel: widget.shortcutModifierLabel,
    );
  }
}

const AppNavigationCopy _copy = AppNavigationCopy(
  appTitle: 'Clock Rhythm',
  clockLabel: 'Clock',
  navigationSemanticsLabel: 'App destinations',
  calendarLabel: 'Calendar',
  dataLabel: 'Data',
  themeLabel: 'Theme',
  settingsLabel: 'Settings',
  routeErrorTitle: 'Cannot open page',
  malformedCalendarDateMessage: 'Invalid calendar date',
  unknownLocationMessage: 'Unknown page',
  backToClockLabel: 'Back to Clock',
);
