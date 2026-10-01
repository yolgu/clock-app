import 'dart:ui' show Tristate;

import 'package:clock_rhythm/app/navigation/app_routes.dart';
import 'package:clock_rhythm/app/presentation/app_navigation_copy.dart';
import 'package:clock_rhythm/app/presentation/windows_top_navigation.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/shared/ui/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a segmented destination toolbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _NavigationHarness(initialIndex: MainDestination.calendar.index),
    );

    expect(find.byType(SegmentedButton<MainDestination>), findsNothing);
    expect(
      tester.getSize(find.byType(WindowsTopNavigation)).height,
      ClockRhythmLayout.windowsNavigationHeight,
    );

    for (final MainDestination destination in MainDestination.values) {
      final Finder destinationFinder = find.byKey(
        ValueKey<String>('windows-destination-${destination.name}'),
      );
      expect(destinationFinder, findsOneWidget);
      expect(
        tester.getSize(destinationFinder).height,
        greaterThanOrEqualTo(ClockRhythmLayout.minimumInteractiveDimension),
      );
    }
  });

  testWidgets('exposes button and selected semantics for each destination', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _NavigationHarness(initialIndex: MainDestination.calendar.index),
    );

    final SemanticsData clock = tester
        .getSemantics(find.bySemanticsLabel('Clock'))
        .getSemanticsData();
    final SemanticsData calendar = tester
        .getSemantics(find.bySemanticsLabel('Calendar'))
        .getSemanticsData();
    final SemanticsNode navigation = tester.getSemantics(
      find.bySemanticsLabel('App destinations'),
    );
    final List<String> destinationLabels = _descendantLabels(
      navigation,
    ).toList(growable: false);

    expect(clock.flagsCollection.isButton, isTrue);
    expect(clock.flagsCollection.isSelected, Tristate.isFalse);
    expect(calendar.flagsCollection.isButton, isTrue);
    expect(calendar.flagsCollection.isSelected, Tristate.isTrue);
    expect(
      destinationLabels,
      containsAll(<String>['Clock', 'Calendar', 'Data', 'Theme', 'Settings']),
    );
    semantics.dispose();
  });

  testWidgets('moves selection and focus with arrows without wrapping', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_NavigationHarnessState> key =
        GlobalKey<_NavigationHarnessState>();
    await tester.pumpWidget(_NavigationHarness(key: key));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(key.currentState!.selectedIndex, MainDestination.clock.index);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(key.currentState!.selectedIndex, MainDestination.calendar.index);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Windows destination: Calendar',
    );

    for (int step = 0; step < 4; step += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }
    expect(key.currentState!.selectedIndex, MainDestination.settings.index);
  });

  testWidgets('clicking a destination preserves the callback contract', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_NavigationHarnessState> key =
        GlobalKey<_NavigationHarnessState>();
    await tester.pumpWidget(_NavigationHarness(key: key));

    await tester.tap(find.text('Theme'));
    await tester.pump();

    expect(key.currentState!.selectedIndex, MainDestination.theme.index);
    expect(key.currentState!.selections, <int>[MainDestination.theme.index]);
  });

  testWidgets('shows tokenized selection and keyboard focus states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _NavigationHarness(initialIndex: MainDestination.calendar.index),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final ThemeData theme = Theme.of(
      tester.element(find.byType(WindowsTopNavigation)),
    );
    final Finder clock = find.byKey(
      const ValueKey<String>('windows-destination-clock'),
    );
    final Finder calendar = find.byKey(
      const ValueKey<String>('windows-destination-calendar'),
    );
    final Iterable<AnimatedContainer> clockContainers = tester
        .widgetList<AnimatedContainer>(
          find.descendant(of: clock, matching: find.byType(AnimatedContainer)),
        );
    final Iterable<AnimatedContainer> calendarContainers = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: calendar,
            matching: find.byType(AnimatedContainer),
          ),
        );

    expect(
      clockContainers.any((AnimatedContainer container) {
        final BoxDecoration? decoration =
            container.foregroundDecoration as BoxDecoration?;
        return decoration?.border?.top.color == theme.focusColor;
      }),
      isTrue,
    );
    expect(
      calendarContainers.any((AnimatedContainer container) {
        final BoxDecoration? decoration =
            container.decoration as BoxDecoration?;
        return decoration?.color == theme.colorScheme.surfaceContainerHighest;
      }),
      isTrue,
    );
  });

  testWidgets('keeps every destination reachable at 200-percent text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(720, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const _NavigationHarness(textScaler: TextScaler.linear(2)),
    );

    expect(tester.takeException(), isNull);
    for (final MainDestination destination in MainDestination.values) {
      expect(
        find.byKey(ValueKey<String>('windows-destination-${destination.name}')),
        findsOneWidget,
      );
    }
  });
}

Iterable<String> _descendantLabels(SemanticsNode node) sync* {
  final List<SemanticsNode> children = node.debugListChildrenInOrder(
    DebugSemanticsDumpOrder.traversalOrder,
  );
  for (final SemanticsNode child in children) {
    if (child.label.isNotEmpty) {
      yield child.label;
    }
    yield* _descendantLabels(child);
  }
}

const AppNavigationCopy _copy = AppNavigationCopy(
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

final class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness({
    this.initialIndex = 0,
    this.textScaler = TextScaler.noScaling,
    super.key,
  });

  final int initialIndex;
  final TextScaler textScaler;

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

final class _NavigationHarnessState extends State<_NavigationHarness> {
  late int selectedIndex = widget.initialIndex;
  final List<int> selections = <int>[];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: widget.textScaler),
          child: child!,
        );
      },
      theme: ClockRhythmTheme.build(
        ThemeCatalog.definitions.first,
        platform: TargetPlatform.windows,
      ),
      home: Scaffold(
        body: WindowsTopNavigation(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            selections.add(index);
            setState(() {
              selectedIndex = index;
            });
          },
          copy: _copy,
        ),
      ),
    );
  }
}
