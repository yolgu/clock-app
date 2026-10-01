import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class ClockRhythmSpace {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
}

/// Generous, continuous-looking corners in the spirit of Apple's grouped
/// interfaces: soft controls, large cards and capsule buttons.
abstract final class ClockRhythmRadius {
  static const double small = 8;
  static const double control = 12;
  static const double card = 20;
  static const double dialog = 24;
  static const double pill = 999;
}

abstract final class ClockRhythmMotion {
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration card = Duration(milliseconds: 300);
  static const Cubic emphasized = Cubic(0, 0, 0.5, 1);

  static Duration accessibleDuration(BuildContext context, Duration duration) {
    final MediaQueryData media = MediaQuery.of(context);
    return media.disableAnimations || media.accessibleNavigation
        ? Duration.zero
        : duration;
  }
}

abstract final class ClockRhythmLayout {
  static const double compactBreakpoint = 600;
  static const double wideBreakpoint = 920;
  static const double maximumContentWidth = 1120;
  static const double minimumInteractiveDimension = 48;
  static const double androidNavigationHeight = 68;
  static const double windowsNavigationHeight = 64;

  static double horizontalInsetFor(double width) {
    if (width < compactBreakpoint) {
      return ClockRhythmSpace.space16;
    }
    if (width < wideBreakpoint) {
      return ClockRhythmSpace.space20;
    }
    return math.max(
      ClockRhythmSpace.space24,
      (width - maximumContentWidth) / 2,
    );
  }

  static double cardPaddingFor(double width) {
    if (width < compactBreakpoint) {
      return ClockRhythmSpace.space16;
    }
    return ClockRhythmSpace.space20;
  }

  static EdgeInsets pageInsetsFor(double width) {
    final double horizontal = horizontalInsetFor(width);
    return EdgeInsets.fromLTRB(
      horizontal,
      ClockRhythmSpace.space24,
      horizontal,
      ClockRhythmSpace.space24,
    );
  }
}

/// An Apple-inspired type ramp (Large Title, Title 1-3, Headline, Callout,
/// Footnote, Caption) tuned for desktop and phone reading distances.
abstract final class ClockRhythmTypography {
  static TextTheme build({
    required TargetPlatform platform,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    final _FontFamilies families = _FontFamilies.forPlatform(platform);
    TextStyle display(
      double size,
      double lineHeight,
      FontWeight weight,
      double tracking,
    ) {
      return _style(
        fontFamily: families.display,
        fallback: families.fallback,
        color: textColor,
        size: size,
        lineHeight: lineHeight,
        weight: weight,
        letterSpacing: tracking,
      );
    }

    TextStyle text(
      double size,
      double lineHeight, {
      FontWeight weight = FontWeight.w400,
      double tracking = 0,
      Color? color,
    }) {
      return _style(
        fontFamily: families.text,
        fallback: families.fallback,
        color: color ?? textColor,
        size: size,
        lineHeight: lineHeight,
        weight: weight,
        letterSpacing: tracking,
      );
    }

    return TextTheme(
      displayLarge: display(56, 64, FontWeight.w700, -1.2),
      displayMedium: display(44, 52, FontWeight.w300, -0.8),
      displaySmall: display(36, 44, FontWeight.w700, -0.6),
      headlineLarge: display(34, 41, FontWeight.w700, -0.5),
      headlineMedium: display(28, 34, FontWeight.w700, -0.4),
      headlineSmall: display(22, 28, FontWeight.w700, -0.3),
      titleLarge: text(20, 25, weight: FontWeight.w600, tracking: -0.3),
      titleMedium: text(17, 22, weight: FontWeight.w600, tracking: -0.2),
      titleSmall: text(15, 20, weight: FontWeight.w600, tracking: -0.1),
      bodyLarge: text(16, 22, tracking: -0.1),
      bodyMedium: text(14, 20),
      bodySmall: text(13, 18, color: mutedTextColor),
      labelLarge: text(15, 20, weight: FontWeight.w600, tracking: -0.1),
      labelMedium: text(13, 18, weight: FontWeight.w600),
      labelSmall: text(12, 16, weight: FontWeight.w500, color: mutedTextColor),
    );
  }

  static TextStyle _style({
    required String fontFamily,
    required List<String> fallback,
    required Color color,
    required double size,
    required double lineHeight,
    required FontWeight weight,
    required double letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallback.isEmpty ? null : fallback,
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: letterSpacing,
    );
  }
}

final class _FontFamilies {
  const _FontFamilies({
    required this.text,
    required this.display,
    this.fallback = const <String>[],
  });

  /// Windows 11 ships Segoe UI Variable, whose optical sizes read closest to
  /// SF Pro. Hangul prefers Noto Sans KR (a Windows optional font) and falls
  /// back to Malgun Gothic; Windows 10 falls back to Segoe UI for Latin.
  factory _FontFamilies.forPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.windows => const _FontFamilies(
        text: 'Segoe UI Variable Text',
        display: 'Segoe UI Variable Display',
        fallback: <String>['Noto Sans KR', 'Segoe UI', 'Malgun Gothic'],
      ),
      TargetPlatform.iOS || TargetPlatform.macOS => const _FontFamilies(
        text: '.AppleSystemUIFont',
        display: '.AppleSystemUIFont',
      ),
      TargetPlatform.android ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => const _FontFamilies(
        text: 'Roboto',
        display: 'Roboto',
      ),
    };
  }

  final String text;
  final String display;
  final List<String> fallback;
}
