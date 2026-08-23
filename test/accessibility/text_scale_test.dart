import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data_page_test_support.dart';

void main() {
  testWidgets('Rhythm status remains readable at 200-percent text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final RhythmConfiguration configuration = RhythmConfiguration.defaults();
    final RhythmSession session = RhythmSession.idle(
      configuration: configuration,
    )..start(configuration);
    final DateTime observedAt = DateTime(2026, 8, 23, 9);
    session.stopForToday(observedAt);
    final RhythmStatusSnapshot snapshot = RhythmStatusSnapshot.capture(
      session: session,
      observedAt: observedAt,
      nextEvent: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: LanguageLocaleMapper.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: RhythmStatusPanel(snapshot: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Done today'), findsOneWidget);
  });

  testWidgets('Data actions remain usable at 200-percent text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildDataPageTestApp(textScaler: const TextScaler.linear(2)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('export-backup')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('import-backup')), findsOneWidget);
  });
}
