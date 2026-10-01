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
    required this.outlineSubtle,
    required this.hoverOverlay,
    required this.pressedOverlay,
    required this.tint,
  });

  final Color surfaceStrong;
  final Color surfaceSoft;
  final Color mutedText;
  final Color accentSecondary;
  final Color focusRing;
  final Color danger;
  final Color sourceText;
  final Color outlineSubtle;
  final Color hoverOverlay;
  final Color pressedOverlay;

  /// The accent tuned for text and glyphs on grouped surfaces.
  final Color tint;

  @override
  ClockRhythmThemeExtension copyWith({
    Color? surfaceStrong,
    Color? surfaceSoft,
    Color? mutedText,
    Color? accentSecondary,
    Color? focusRing,
    Color? danger,
    Color? sourceText,
    Color? outlineSubtle,
    Color? hoverOverlay,
    Color? pressedOverlay,
    Color? tint,
  }) {
    return ClockRhythmThemeExtension(
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      mutedText: mutedText ?? this.mutedText,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      focusRing: focusRing ?? this.focusRing,
      danger: danger ?? this.danger,
      sourceText: sourceText ?? this.sourceText,
      outlineSubtle: outlineSubtle ?? this.outlineSubtle,
      hoverOverlay: hoverOverlay ?? this.hoverOverlay,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
      tint: tint ?? this.tint,
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
      outlineSubtle: Color.lerp(outlineSubtle, other.outlineSubtle, t)!,
      hoverOverlay: Color.lerp(hoverOverlay, other.hoverOverlay, t)!,
      pressedOverlay: Color.lerp(pressedOverlay, other.pressedOverlay, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
    );
  }
}
