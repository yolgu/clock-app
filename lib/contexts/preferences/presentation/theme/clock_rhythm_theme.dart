import 'package:flutter/material.dart';

import 'clock_rhythm_theme_extension.dart';
import 'theme_catalog.dart';

abstract final class ClockRhythmTheme {
  static ThemeData build(ThemeDefinition definition) {
    final Color surface = definition.surface.color;
    final Color primary = definition.accentPrimary.color;
    final Color secondary = definition.accentSecondary.color;
    final Color onSurface = _readableForeground(
      preferred: definition.text.color,
      background: surface,
      minimumContrast: 4.5,
    );
    final Color onPrimary = _readableForeground(
      preferred: const Color(0xFF05070A),
      background: primary,
      minimumContrast: 4.5,
    );
    final Color onSecondary = _readableForeground(
      preferred: const Color(0xFF05070A),
      background: secondary,
      minimumContrast: 4.5,
    );
    final Color error = _readableForeground(
      preferred: definition.danger.color,
      background: surface,
      minimumContrast: 4.5,
    );
    final Color focusRing = _readableForeground(
      preferred: primary,
      background: surface,
      minimumContrast: 3,
    );
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: error,
      onError: _highestContrastForeground(error),
      surface: surface,
      onSurface: onSurface,
    );
    final ClockRhythmThemeExtension extension = ClockRhythmThemeExtension(
      surfaceStrong: Color.lerp(surface, onSurface, 0.08)!,
      surfaceSoft: Color.lerp(surface, onSurface, 0.04)!,
      mutedText: Color.lerp(onSurface, surface, 0.24)!,
      accentSecondary: secondary,
      focusRing: focusRing,
      danger: error,
      sourceText: definition.text.color,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: definition.background.color,
      focusColor: focusRing,
      disabledColor: extension.mutedText.withValues(alpha: 0.48),
      extensions: <ThemeExtension<dynamic>>[extension],
    );
  }

  static Color _readableForeground({
    required Color preferred,
    required Color background,
    required double minimumContrast,
  }) {
    if (_contrast(preferred, background) >= minimumContrast) {
      return preferred;
    }
    return _highestContrastForeground(background);
  }

  static Color _highestContrastForeground(Color background) {
    const Color light = Color(0xFFFFFFFF);
    const Color dark = Color(0xFF000000);
    return _contrast(light, background) >= _contrast(dark, background)
        ? light
        : dark;
  }

  static double _contrast(Color first, Color second) {
    final double firstLuminance = first.computeLuminance();
    final double secondLuminance = second.computeLuminance();
    final double lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final double darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
