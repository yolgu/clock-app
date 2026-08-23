import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('visible ticker rebuilds only its clock subtree', (
    WidgetTester tester,
  ) async {
    final GlobalKey<TickerHarnessState> key = GlobalKey<TickerHarnessState>();
    final FakeNow now = FakeNow(DateTime(2026, 8, 23, 6, 7));
    await tester.pumpWidget(
      MaterialApp(
        home: TickerHarness(key: key, now: now.call),
      ),
    );
    await tester.pump();
    final int outerBuilds = key.currentState!.outerBuilds;
    final int clockBuilds = key.currentState!.clockBuilds;

    await tester.pump(const Duration(seconds: 2));

    expect(key.currentState!.outerBuilds, outerBuilds);
    expect(key.currentState!.clockBuilds, greaterThan(clockBuilds));
  });

  testWidgets('ticker cancels offstage and samples immediately on re-entry', (
    WidgetTester tester,
  ) async {
    final GlobalKey<TickerHarnessState> key = GlobalKey<TickerHarnessState>();
    final FakeNow now = FakeNow(DateTime(2026, 8, 23, 6, 7));
    await tester.pumpWidget(
      MaterialApp(
        home: TickerHarness(key: key, now: now.call),
      ),
    );
    await tester.pump();
    key.currentState!.setVisible(false);
    await tester.pump();
    final int callsWhileHidden = now.calls;

    await tester.pump(const Duration(seconds: 3));
    expect(now.calls, callsWhileHidden);

    key.currentState!.setVisible(true);
    await tester.pump();
    expect(now.calls, callsWhileHidden + 1);
    expect(key.currentState!.visibleEntries, 2);
  });

  testWidgets('ticker pauses with the app lifecycle and reconciles on resume', (
    WidgetTester tester,
  ) async {
    final GlobalKey<TickerHarnessState> key = GlobalKey<TickerHarnessState>();
    final FakeNow now = FakeNow(DateTime(2026, 8, 23, 6, 7));
    await tester.pumpWidget(
      MaterialApp(
        home: TickerHarness(key: key, now: now.call),
      ),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final int pausedCalls = now.calls;

    await tester.pump(const Duration(seconds: 3));
    expect(now.calls, pausedCalls);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(now.calls, pausedCalls + 1);
    expect(key.currentState!.visibleEntries, 2);
  });

  testWidgets('analog clock is decorative and digital clock is not live', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: LanguageLocaleMapper.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              AnalogClock(now: DateTime(2026, 8, 23, 6, 7, 8)),
              DigitalClock(now: DateTime(2026, 8, 23, 6, 7, 8)),
            ],
          ),
        ),
      ),
    );

    final SemanticsNode digital = tester.getSemantics(
      find.byKey(const ValueKey<String>('digital-clock-semantics')),
    );
    expect(digital.getSemanticsData().label, 'Current time: 06 : 07 : 08');
    expect(digital.getSemanticsData().flagsCollection.isLiveRegion, isFalse);
    expect(
      find.bySemanticsLabel(RegExp('analog', caseSensitive: false)),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('analog clock honors the layout size supplied by its owner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AnalogClock(now: DateTime(2026, 8, 23, 6, 7, 8), size: 180),
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('analog-clock-repaint-boundary')),
      ),
      const Size.square(180),
    );
  });
}

final class FakeNow {
  FakeNow(this._current);

  DateTime _current;
  int calls = 0;

  DateTime call() {
    calls += 1;
    final DateTime sampled = _current;
    _current = _current.add(const Duration(seconds: 1));
    return sampled;
  }
}

final class TickerHarness extends StatefulWidget {
  const TickerHarness({required this.now, super.key});

  final DateTime Function() now;

  @override
  State<TickerHarness> createState() => TickerHarnessState();
}

final class TickerHarnessState extends State<TickerHarness> {
  bool visible = true;
  int outerBuilds = 0;
  int clockBuilds = 0;
  int visibleEntries = 0;

  void setVisible(bool next) {
    setState(() => visible = next);
  }

  @override
  Widget build(BuildContext context) {
    outerBuilds += 1;
    return TickerMode(
      enabled: visible,
      child: VisibleClockTicker(
        now: widget.now,
        onBecameVisible: () => visibleEntries += 1,
        builder: (BuildContext context, DateTime now) {
          clockBuilds += 1;
          return Text(now.toIso8601String());
        },
      ),
    );
  }
}
