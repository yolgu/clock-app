import 'package:clock_rhythm/shared/ui/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adaptive mode respects available width and 200-percent text', () {
    expect(
      AdaptiveContentLayout.resolve(
        constraints: const BoxConstraints(maxWidth: 1280),
        textScaler: TextScaler.noScaling,
        wideMinimumWidth: 920,
        maximumWideBodyTextSize: 24,
      ),
      AdaptiveContentMode.wide,
    );
    expect(
      AdaptiveContentLayout.resolve(
        constraints: const BoxConstraints(maxWidth: 919),
        textScaler: TextScaler.noScaling,
        wideMinimumWidth: 920,
        maximumWideBodyTextSize: 24,
      ),
      AdaptiveContentMode.compact,
    );
    expect(
      AdaptiveContentLayout.resolve(
        constraints: const BoxConstraints(maxWidth: 1280),
        textScaler: const TextScaler.linear(2),
        wideMinimumWidth: 920,
        maximumWideBodyTextSize: 24,
      ),
      AdaptiveContentMode.compact,
    );
  });

  testWidgets('minimum target provides at least 48 logical pixels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: MinimumTapTarget(
            key: ValueKey<String>('target'),
            child: SizedBox(width: 8, height: 8),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey<String>('target'))),
      const Size(48, 48),
    );
  });

  testWidgets('status feedback is exposed as a live semantic region', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SemanticStatusAnnouncement(
          message: 'Saved',
          child: Text('Saved'),
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(
      find.byType(SemanticStatusAnnouncement),
    );
    expect(node.getSemanticsData().label, 'Saved');
    expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('focus ring exposes a visible theme focus border', (
    WidgetTester tester,
  ) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'focus ring test');
    addTearDown(focusNode.dispose);
    const Color focusColor = Color(0xFF00FFF0);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(focusColor: focusColor),
        home: Center(
          child: FocusRing(
            focusNode: focusNode,
            child: const SizedBox(width: 48, height: 48),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final AnimatedContainer ring = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(FocusRing),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final BoxDecoration decoration =
        ring.foregroundDecoration! as BoxDecoration;
    expect(decoration.border!.top.color, focusColor);
    expect(decoration.border!.top.width, greaterThanOrEqualTo(2));
  });
}
