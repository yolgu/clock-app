import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_rhythm_actions.dart';

void main() {
  testWidgets('controls expose only valid commands for each session state', (
    WidgetTester tester,
  ) async {
    final FakeRhythmActions actions = FakeRhythmActions();
    await tester.pumpWidget(_testApp(actions, const RhythmControls()));
    await tester.pumpAndSettle();

    expect(_enabled(tester, 'start-rhythm'), isTrue);
    expect(_enabled(tester, 'pause-rhythm'), isFalse);
    expect(_enabled(tester, 'resume-rhythm'), isFalse);
    expect(_enabled(tester, 'stop-rhythm-for-today'), isFalse);

    await tester.tap(find.byKey(const ValueKey<String>('start-rhythm')));
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'start-rhythm'), isFalse);
    expect(_enabled(tester, 'pause-rhythm'), isTrue);
    expect(_enabled(tester, 'resume-rhythm'), isFalse);
    expect(_enabled(tester, 'stop-rhythm-for-today'), isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('pause-rhythm')));
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'pause-rhythm'), isFalse);
    expect(_enabled(tester, 'resume-rhythm'), isTrue);
    expect(_enabled(tester, 'stop-rhythm-for-today'), isTrue);
  });

  testWidgets('permission denial explains the failure without claiming Running', (
    WidgetTester tester,
  ) async {
    final FakeRhythmActions actions = FakeRhythmActions()
      ..startFailure = RhythmStartFailure.notificationAndExactAlarmPermission;
    await tester.pumpWidget(_testApp(actions, const RhythmControls()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('start-rhythm')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Notification permission and exact-alarm access are required to start focus/rest delivery.',
      ),
      findsOne,
    );
    expect(_enabled(tester, 'start-rhythm'), isTrue);
    expect(actions.current.status, RhythmSessionStatus.idle);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(
      actions.calls,
      contains('settings:notificationAndExactAlarmPermission'),
    );
    expect(actions.calls.where((String call) => call == 'start'), hasLength(1));
  });

  testWidgets(
    'beta coexistence warning acknowledges only confirmation before Start',
    (WidgetTester tester) async {
      final FakeRhythmActions actions = FakeRhythmActions();
      final _FakeLegacyCoexistenceWarning warning =
          _FakeLegacyCoexistenceWarning(required: true);
      await tester.pumpWidget(
        _testApp(actions, const RhythmControls(), coexistenceWarning: warning),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('start-rhythm')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('legacy-coexistence-warning')),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(warning.acknowledgeCount, 0);
      expect(actions.calls.where((String call) => call == 'start'), isEmpty);

      await tester.tap(find.byKey(const ValueKey<String>('start-rhythm')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I paused and quit it'));
      await tester.pumpAndSettle();

      expect(warning.acknowledgeCount, 1);
      expect(
        actions.calls.where((String call) => call == 'start'),
        hasLength(1),
      );
      expect(actions.current.status, RhythmSessionStatus.running);
    },
  );

  testWidgets('status panel distinguishes an armed outside-window run', (
    WidgetTester tester,
  ) async {
    final RhythmConfiguration configuration = RhythmConfiguration.defaults();
    final RhythmSession session = RhythmSession.idle(
      configuration: configuration,
    )..start(configuration);
    final DateTime observedAt = DateTime(2026, 8, 23, 19);
    final RhythmStatusSnapshot snapshot = RhythmStatusSnapshot.capture(
      session: session,
      observedAt: observedAt,
      nextEvent: session.nextEventAfter(observedAt),
    );

    await tester.pumpWidget(
      _localizedApp(RhythmStatusPanel(snapshot: snapshot)),
    );

    expect(find.text('Running'), findsOne);
    expect(find.text('Next notification: 05:50'), findsOne);
    expect(
      find.text('The current time is outside the focus window.'),
      findsOne,
    );
  });
}

/// Controls that do not apply to the current session are not shown, so an
/// absent control counts as unavailable.
bool _enabled(WidgetTester tester, String key) {
  final Finder finder = find.byKey(ValueKey<String>(key));
  if (finder.evaluate().isEmpty) {
    return false;
  }
  return tester.widget<ButtonStyleButton>(finder).onPressed != null;
}

Widget _testApp(
  FakeRhythmActions actions,
  Widget child, {
  LegacyCoexistenceWarning? coexistenceWarning,
}) {
  return ProviderScope(
    overrides: [
      rhythmActionsProvider.overrideWithValue(actions),
      if (coexistenceWarning != null)
        legacyCoexistenceWarningProvider.overrideWithValue(coexistenceWarning),
    ],
    child: _localizedApp(child),
  );
}

Widget _localizedApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: LanguageLocaleMapper.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

final class _FakeLegacyCoexistenceWarning implements LegacyCoexistenceWarning {
  _FakeLegacyCoexistenceWarning({required this.required});

  final bool required;
  int acknowledgeCount = 0;

  @override
  Future<void> acknowledge() async {
    acknowledgeCount += 1;
  }

  @override
  Future<bool> shouldWarnBeforeStart() async => required;
}
