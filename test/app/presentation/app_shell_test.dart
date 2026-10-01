import 'package:clock_rhythm/app/clock_rhythm_app.dart';
import 'package:clock_rhythm/app/navigation/app_router.dart';
import 'package:clock_rhythm/app/navigation/app_routes.dart';
import 'package:clock_rhythm/app/platform_presentation_profile.dart';
import 'package:clock_rhythm/app/presentation/android_bottom_navigation.dart';
import 'package:clock_rhythm/app/presentation/app_navigation_copy.dart';
import 'package:clock_rhythm/app/presentation/route_error_page.dart';
import 'package:clock_rhythm/app/presentation/windows_top_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AppNavigationCopy copy = AppNavigationCopy(
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

  testWidgets('Android uses bottom navigation and Back returns to Clock', (
    WidgetTester tester,
  ) async {
    final ClockRhythmRouter clockRouter = ClockRhythmRouter(
      profile: PlatformPresentationProfile.android,
      navigationCopy: copy,
    );
    addTearDown(clockRouter.dispose);

    await tester.pumpWidget(ClockRhythmApp(router: clockRouter.router));
    await tester.pumpAndSettle();

    expect(find.byType(AndroidBottomNavigation), findsOneWidget);
    expect(find.byType(WindowsTopNavigation), findsNothing);
    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    expect(clockRouter.router.state.uri.path, '/data');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(clockRouter.router.state.uri.path, '/clock');
  });

  testWidgets(
    'Windows uses top navigation and Ctrl+4/5 select Theme and Settings',
    (WidgetTester tester) async {
      final ClockRhythmRouter clockRouter = ClockRhythmRouter(
        profile: PlatformPresentationProfile.windows,
        navigationCopy: copy,
      );
      addTearDown(clockRouter.dispose);
      await tester.pumpWidget(ClockRhythmApp(router: clockRouter.router));
      await tester.pumpAndSettle();

      expect(find.byType(WindowsTopNavigation), findsOneWidget);
      expect(find.byType(AndroidBottomNavigation), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(clockRouter.router.state.uri.path, '/theme');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(clockRouter.router.state.uri.path, '/settings');
    },
  );

  testWidgets('both platforms expose a Settings destination', (
    WidgetTester tester,
  ) async {
    for (final PlatformPresentationProfile profile
        in PlatformPresentationProfile.values) {
      final ClockRhythmRouter clockRouter = ClockRhythmRouter(
        profile: profile,
        navigationCopy: copy,
      );
      await tester.pumpWidget(ClockRhythmApp(router: clockRouter.router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      expect(
        clockRouter.router.state.uri.path,
        '/settings',
        reason: '$profile',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      clockRouter.dispose();
    }
  });

  testWidgets('indexed branches retain their form state', (
    WidgetTester tester,
  ) async {
    final ClockRhythmRouter clockRouter = ClockRhythmRouter(
      profile: PlatformPresentationProfile.android,
      navigationCopy: copy,
      pages: AppDestinationPages(
        clock: (_) => const Text('Clock page'),
        calendar: (_, _) => const TextField(key: Key('calendar-field')),
        data: (_) => const Text('Data page'),
        theme: (_) => const Text('Theme page'),
        settings: (_) => const Text('Settings page'),
      ),
    );
    addTearDown(clockRouter.dispose);
    await tester.pumpWidget(ClockRhythmApp(router: clockRouter.router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('calendar-field')), 'kept');
    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('kept'), findsOneWidget);
  });

  testWidgets(
    'process restoration retains the selected branch, calendar query, and branch state',
    (WidgetTester tester) async {
      final GlobalKey<_RestorableRouterHarnessState> harnessKey =
          GlobalKey<_RestorableRouterHarnessState>();
      final AppDestinationPages pages = AppDestinationPages(
        clock: (_) => const Text('Clock page'),
        calendar: (_, AppCalendarDate? selectedDate) => Column(
          children: <Widget>[
            Text(selectedDate?.iso8601 ?? 'No selected date'),
            const TextField(
              key: Key('restorable-calendar-field'),
              restorationId: 'restorable-calendar-field',
            ),
          ],
        ),
        data: (_) => const Text('Data page'),
        theme: (_) => const Text('Theme page'),
        settings: (_) => const Text('Settings page'),
      );
      await tester.pumpWidget(
        _RestorableRouterHarness(key: harnessKey, pages: pages, copy: copy),
      );
      await tester.pumpAndSettle();
      final ClockRhythmRouter originalRouter =
          harnessKey.currentState!.clockRouter;

      originalRouter.router.go('/calendar?date=2026-08-23');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('restorable-calendar-field')),
        'restored branch state',
      );
      await tester.pump();

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      final ClockRhythmRouter restoredRouter =
          harnessKey.currentState!.clockRouter;

      expect(restoredRouter, isNot(same(originalRouter)));
      expect(
        restoredRouter.router.state.uri.toString(),
        '/calendar?date=2026-08-23',
      );
      expect(find.text('2026-08-23'), findsOneWidget);
      expect(find.text('restored branch state'), findsOneWidget);
    },
  );

  testWidgets('moving branches releases focus from hidden content', (
    WidgetTester tester,
  ) async {
    final FocusNode calendarFieldFocus = FocusNode(
      debugLabel: 'calendar field',
    );
    addTearDown(calendarFieldFocus.dispose);
    final ClockRhythmRouter clockRouter = ClockRhythmRouter(
      profile: PlatformPresentationProfile.windows,
      navigationCopy: copy,
      pages: AppDestinationPages(
        clock: (_) => const Text('Clock page'),
        calendar: (_, _) => TextField(
          key: const Key('calendar-focus-field'),
          focusNode: calendarFieldFocus,
        ),
        data: (_) => const Text('Data page'),
        theme: (_) => const Text('Theme page'),
        settings: (_) => const Text('Settings page'),
      ),
    );
    addTearDown(clockRouter.dispose);
    await tester.pumpWidget(ClockRhythmApp(router: clockRouter.router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    calendarFieldFocus.requestFocus();
    await tester.pump();
    expect(calendarFieldFocus.hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(clockRouter.router.state.uri.path, '/data');
    expect(calendarFieldFocus.hasFocus, isFalse);
  });

  testWidgets('malformed date and unknown location show explicit errors', (
    WidgetTester tester,
  ) async {
    final ClockRhythmRouter clockRouter = ClockRhythmRouter(
      profile: PlatformPresentationProfile.android,
      navigationCopy: copy,
    );
    addTearDown(clockRouter.dispose);
    await tester.pumpWidget(ClockRhythmApp(router: clockRouter.router));

    clockRouter.router.go('/calendar?date=2026-02-29');
    await tester.pumpAndSettle();
    expect(find.byType(RouteErrorPage), findsOneWidget);
    expect(find.text('Invalid calendar date'), findsOneWidget);

    clockRouter.router.go('/missing');
    await tester.pumpAndSettle();
    expect(find.byType(RouteErrorPage), findsOneWidget);
    expect(find.text('Unknown page'), findsOneWidget);
  });
}

final class _RestorableRouterHarness extends StatefulWidget {
  const _RestorableRouterHarness({
    required this.pages,
    required this.copy,
    super.key,
  });

  final AppDestinationPages pages;
  final AppNavigationCopy copy;

  @override
  State<_RestorableRouterHarness> createState() =>
      _RestorableRouterHarnessState();
}

final class _RestorableRouterHarnessState
    extends State<_RestorableRouterHarness> {
  late final ClockRhythmRouter clockRouter;

  @override
  void initState() {
    super.initState();
    clockRouter = ClockRhythmRouter(
      profile: PlatformPresentationProfile.android,
      navigationCopy: widget.copy,
      pages: widget.pages,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClockRhythmApp(router: clockRouter.router);
  }

  @override
  void dispose() {
    clockRouter.dispose();
    super.dispose();
  }
}
