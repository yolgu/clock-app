import 'package:flutter/material.dart';

@immutable
final class ClockRhythmThemeExtension
    extends ThemeExtension<ClockRhythmThemeExtension> {
  const ClockRhythmThemeExtension({
    required this.surfaceStrong,
    required this.surfaceSoft,
    required this.mutedText,
    required this.accentSecondary,
    required this.focusRing,
    required this.danger,
    required this.sourceText,
  });

  final Color surfaceStrong;
  final Color surfaceSoft;
  final Color mutedText;
  final Color accentSecondary;
  final Color focusRing;
  final Color danger;
  final Color sourceText;

  @override
  ClockRhythmThemeExtension copyWith({
    Color? surfaceStrong,
    Color? surfaceSoft,
    Color? mutedText,
    Color? accentSecondary,
    Color? focusRing,
    Color? danger,
    Color? sourceText,
  }) {
    return ClockRhythmThemeExtension(
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      mutedText: mutedText ?? this.mutedText,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      focusRing: focusRing ?? this.focusRing,
      danger: danger ?? this.danger,
      sourceText: sourceText ?? this.sourceText,
    );
  }

  @override
  ClockRhythmThemeExtension lerp(
    covariant ClockRhythmThemeExtension? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }
    return ClockRhythmThemeExtension(
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      sourceText: Color.lerp(sourceText, other.sourceText, t)!,
    );
  }
}
