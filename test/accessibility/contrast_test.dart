import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final ThemeDefinition definition in ThemeCatalog.definitions) {
    testWidgets('${definition.id.id} rendered controls meet text contrast', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final RhythmConfiguration configuration = RhythmConfiguration.defaults();
      final RhythmSession session = RhythmSession.idle(
        configuration: configuration,
      );
      final DateTime observedAt = DateTime(2026, 8, 23, 9);
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
          theme: ClockRhythmTheme.build(definition),
          home: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RhythmStatusPanel(snapshot: snapshot),
                const FilledButton(onPressed: null, child: Text('Disabled')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }
}
