import 'package:clock_rhythm/app/clock_rhythm_app.dart';
import 'package:clock_rhythm/app/navigation/app_router.dart';
import 'package:clock_rhythm/app/platform_presentation_profile.dart';
import 'package:clock_rhythm/app/presentation/app_navigation_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts Clock Rhythm without the generated counter example', (
    WidgetTester tester,
  ) async {
    const AppNavigationCopy copy = AppNavigationCopy(
      clockLabel: 'Clock Rhythm',
      navigationSemanticsLabel: 'App destinations',
      calendarLabel: 'Calendar',
      dataLabel: 'Data',
      themeLabel: 'Theme',
      routeErrorTitle: 'Cannot open page',
      malformedCalendarDateMessage: 'Invalid calendar date',
      unknownLocationMessage: 'Unknown page',
      backToClockLabel: 'Back to Clock',
    );
    final ClockRhythmRouter router = ClockRhythmRouter(
      profile: PlatformPresentationProfile.windows,
      navigationCopy: copy,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ClockRhythmApp(router: router.router));
    await tester.pumpAndSettle();

    expect(find.text('Clock Rhythm'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.textContaining('pushed the button'), findsNothing);
  });
}
