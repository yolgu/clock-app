import 'package:clock_rhythm/contexts/preferences/presentation/theme/clock_rhythm_theme.dart';
import 'package:clock_rhythm/contexts/preferences/presentation/theme/clock_rhythm_theme_extension.dart';
import 'package:clock_rhythm/contexts/preferences/presentation/theme/theme_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final ThemeDefinition definition in ThemeCatalog.definitions) {
    for (final Brightness brightness in Brightness.values) {
      test('${definition.id.id} ${brightness.name} has complete accessible '
          'derived roles', () {
        final ThemeData theme = ClockRhythmTheme.build(
          definition,
          brightness: brightness,
        );
        final ClockRhythmThemeExtension extension = theme
            .extension<ClockRhythmThemeExtension>()!;
        final ThemeSeeds seeds = definition.seedsFor(brightness);

        expect(theme.brightness, brightness);
        expect(theme.colorScheme.surface, seeds.surface.color);
        expect(theme.scaffoldBackgroundColor, seeds.background.color);
        expect(
          _contrast(theme.colorScheme.onSurface, theme.colorScheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(theme.colorScheme.onPrimary, theme.colorScheme.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(extension.focusRing, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(theme.colorScheme.outline, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(extension.mutedText, theme.colorScheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(
            theme.colorScheme.onPrimaryContainer,
            theme.colorScheme.primaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(
            theme.colorScheme.onSecondaryContainer,
            theme.colorScheme.secondaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(
            theme.colorScheme.onErrorContainer,
            theme.colorScheme.errorContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(extension.accentSecondary, seeds.accentSecondary.color);
        expect(extension.sourceText, seeds.text.color);
      });
    }
  }
}

double _contrast(Color first, Color second) {
  final double lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final double darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
