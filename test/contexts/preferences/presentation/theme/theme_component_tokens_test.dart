import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/shared/ui/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds Apple-style Windows typography and component geometry', () {
    final ThemeData theme = ClockRhythmTheme.build(
      ThemeCatalog.definitions.first,
      platform: TargetPlatform.windows,
    );
    final ClockRhythmThemeExtension extension = theme
        .extension<ClockRhythmThemeExtension>()!;

    expect(theme.platform, TargetPlatform.windows);
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Segoe UI Variable Text');
    expect(theme.textTheme.bodyLarge?.fontSize, 16);

    final Color surface = theme.colorScheme.surface;
    final Color onSurface = theme.colorScheme.onSurface;
    expect(
      theme.colorScheme.surfaceContainerLow,
      Color.lerp(surface, onSurface, 0.04),
    );
    expect(
      theme.colorScheme.surfaceContainerHigh,
      Color.lerp(surface, onSurface, 0.09),
    );
    expect(
      theme.colorScheme.surfaceContainerHighest,
      Color.lerp(surface, onSurface, 0.13),
    );
    expect(extension.outlineSubtle, Color.lerp(surface, onSurface, 0.09));
    expect(extension.hoverOverlay, onSurface.withValues(alpha: 0.09));
    expect(extension.pressedOverlay, onSurface.withValues(alpha: 0.13));
    expect(theme.hoverColor, onSurface.withValues(alpha: 0.04));

    final RoundedRectangleBorder cardShape =
        theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(_radiusOf(cardShape.borderRadius), ClockRhythmRadius.card);
    expect(cardShape.side, BorderSide.none);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.shadowColor, Colors.transparent);
    expect(theme.cardTheme.surfaceTintColor, Colors.transparent);

    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve(
        const <WidgetState>{},
      ),
      const Size(48, 48),
    );
    expect(
      _radiusOf(
        (theme.filledButtonTheme.style?.shape?.resolve(const <WidgetState>{})!
                as RoundedRectangleBorder)
            .borderRadius,
      ),
      ClockRhythmRadius.pill,
    );
    expect(
      theme.iconButtonTheme.style?.minimumSize?.resolve(const <WidgetState>{}),
      const Size.square(48),
    );

    final OutlineInputBorder inputBorder =
        theme.inputDecorationTheme.border! as OutlineInputBorder;
    expect(_radiusOf(inputBorder.borderRadius), ClockRhythmRadius.control);
    final RoundedRectangleBorder dialogShape =
        theme.dialogTheme.shape! as RoundedRectangleBorder;
    expect(_radiusOf(dialogShape.borderRadius), ClockRhythmRadius.dialog);
    expect(
      _radiusOf(
        (theme.segmentedButtonTheme.style?.shape?.resolve(
                  const <WidgetState>{},
                )!
                as RoundedRectangleBorder)
            .borderRadius,
      ),
      ClockRhythmRadius.pill,
    );
    expect(
      theme.navigationBarTheme.height,
      ClockRhythmLayout.androidNavigationHeight,
    );
  });

  test(
    'builds explicit Android typography without changing palette colors',
    () {
      final ThemeDefinition definition = ThemeCatalog.definitions.first;
      final ThemeData theme = ClockRhythmTheme.build(
        definition,
        platform: TargetPlatform.android,
      );

      expect(theme.platform, TargetPlatform.android);
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Roboto');
      expect(theme.scaffoldBackgroundColor, definition.background.color);
      expect(theme.colorScheme.surface, definition.surface.color);
      expect(theme.colorScheme.primary, definition.accentPrimary.color);
      expect(theme.colorScheme.secondary, definition.accentSecondary.color);
    },
  );
}

double _radiusOf(BorderRadiusGeometry geometry) {
  final BorderRadius radius = geometry.resolve(TextDirection.ltr);
  return radius.topLeft.x;
}
