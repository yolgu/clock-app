import 'package:clock_rhythm/shared/ui/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines the approved spacing, radius, size, and motion scales', () {
    expect(
      <double>[
        ClockRhythmSpace.space4,
        ClockRhythmSpace.space8,
        ClockRhythmSpace.space12,
        ClockRhythmSpace.space16,
        ClockRhythmSpace.space20,
        ClockRhythmSpace.space24,
        ClockRhythmSpace.space28,
        ClockRhythmSpace.space32,
      ],
      <double>[4, 8, 12, 16, 20, 24, 28, 32],
    );
    expect(ClockRhythmRadius.small, 8);
    expect(ClockRhythmRadius.control, 12);
    expect(ClockRhythmRadius.card, 20);
    expect(ClockRhythmRadius.dialog, 24);
    expect(ClockRhythmRadius.pill, 999);
    expect(ClockRhythmLayout.minimumInteractiveDimension, 48);
    expect(ClockRhythmLayout.androidNavigationHeight, 68);
    expect(ClockRhythmLayout.windowsNavigationHeight, 64);
    expect(ClockRhythmMotion.fast, const Duration(milliseconds: 100));
    expect(ClockRhythmMotion.standard, const Duration(milliseconds: 200));
    expect(ClockRhythmMotion.card, const Duration(milliseconds: 300));
    expect(ClockRhythmMotion.emphasized, const Cubic(0, 0, 0.5, 1));
  });

  test('resolves responsive page insets and card padding', () {
    expect(ClockRhythmLayout.horizontalInsetFor(360), 16);
    expect(ClockRhythmLayout.horizontalInsetFor(599), 16);
    expect(ClockRhythmLayout.horizontalInsetFor(600), 20);
    expect(ClockRhythmLayout.horizontalInsetFor(919), 20);
    expect(ClockRhythmLayout.horizontalInsetFor(920), 24);
    expect(ClockRhythmLayout.horizontalInsetFor(1280), 80);

    expect(ClockRhythmLayout.cardPaddingFor(360), 16);
    expect(ClockRhythmLayout.cardPaddingFor(600), 20);
    expect(ClockRhythmLayout.cardPaddingFor(920), 20);
    expect(
      ClockRhythmLayout.pageInsetsFor(1280),
      const EdgeInsets.fromLTRB(80, 24, 80, 24),
    );
  });

  test('builds the approved platform typography', () {
    final TextTheme windows = ClockRhythmTypography.build(
      platform: TargetPlatform.windows,
      textColor: Colors.white,
      mutedTextColor: Colors.white70,
    );
    final TextTheme android = ClockRhythmTypography.build(
      platform: TargetPlatform.android,
      textColor: Colors.white,
      mutedTextColor: Colors.white70,
    );

    expect(windows.displayLarge?.fontFamily, 'Segoe UI Variable Display');
    expect(windows.bodyLarge?.fontFamily, 'Segoe UI Variable Text');
    expect(windows.bodyLarge?.fontFamilyFallback, <String>[
      'Noto Sans KR',
      'Segoe UI',
      'Malgun Gothic',
    ]);
    expect(android.displayLarge?.fontFamily, 'Roboto');
    expect(windows.displayLarge?.fontSize, 56);
    expect(windows.displayLarge?.height, closeTo(64 / 56, 0.0001));
    expect(windows.displayLarge?.fontWeight, FontWeight.w700);
    expect(windows.displayMedium?.fontSize, 44);
    expect(windows.headlineLarge?.fontSize, 34);
    expect(windows.headlineLarge?.height, closeTo(41 / 34, 0.0001));
    expect(windows.headlineLarge?.fontWeight, FontWeight.w700);
    expect(windows.headlineMedium?.fontSize, 28);
    expect(windows.headlineMedium?.height, closeTo(34 / 28, 0.0001));
    expect(windows.titleLarge?.fontSize, 20);
    expect(windows.titleMedium?.fontSize, 17);
    expect(windows.bodyLarge?.fontSize, 16);
    expect(windows.bodyLarge?.height, closeTo(22 / 16, 0.0001));
    expect(windows.bodyMedium?.fontSize, 14);
    expect(windows.bodySmall?.fontSize, 13);
    expect(windows.labelMedium?.fontSize, 13);
    expect(windows.labelMedium?.height, closeTo(18 / 13, 0.0001));
    expect(windows.labelMedium?.fontWeight, FontWeight.w600);
  });

  testWidgets('ClockRhythmCard applies a borderless grouped panel contract', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const Color outlineColor = Color(0x33FFFFFF);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF101010),
            outlineVariant: outlineColor,
          ),
        ),
        home: const Scaffold(
          body: ClockRhythmCard.padded(
            child: Text('content', key: ValueKey<String>('card-content')),
          ),
        ),
      ),
    );

    final Finder card = find.byType(ClockRhythmCard);
    final Material material = tester.widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)).first,
    );
    final RoundedRectangleBorder shape =
        material.shape! as RoundedRectangleBorder;
    final Iterable<Padding> paddingAncestors = tester.widgetList<Padding>(
      find.ancestor(
        of: find.byKey(const ValueKey<String>('card-content')),
        matching: find.byType(Padding),
      ),
    );

    final BorderRadius radius = shape.borderRadius as BorderRadius;

    expect(radius.topLeft.x, ClockRhythmRadius.card);
    expect(material.elevation, 0);
    expect(material.shadowColor, Colors.transparent);
    expect(shape.side.width, 0.5);
    expect(shape.side.color, Colors.white.withValues(alpha: 0.07));
    expect(
      paddingAncestors.any(
        (Padding padding) =>
            padding.padding == const EdgeInsets.all(ClockRhythmSpace.space16),
      ),
      isTrue,
    );
  });

  testWidgets('motion is disabled for accessibility preferences', (
    WidgetTester tester,
  ) async {
    Duration? resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (BuildContext context) {
            resolved = ClockRhythmMotion.accessibleDuration(
              context,
              ClockRhythmMotion.card,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, Duration.zero);
  });
}
