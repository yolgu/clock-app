import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../../../shared/ui/public.dart'
    show
        ClockRhythmLayout,
        ClockRhythmMotion,
        ClockRhythmRadius,
        ClockRhythmSpace,
        ClockRhythmTypography;
import 'clock_rhythm_theme_extension.dart';
import 'theme_catalog.dart';

/// Builds the minimal appearance from a palette in one mode: hairline-
/// bordered surfaces, compact rounded-rectangle controls, outlined fields, a
/// tab bar that marks the selected destination with a tinted pill, and
/// derived roles that stay readable in every palette and mode.
abstract final class ClockRhythmTheme {
  static ThemeData build(
    ThemeDefinition definition, {
    Brightness brightness = Brightness.dark,
    TargetPlatform? platform,
  }) {
    final TargetPlatform resolvedPlatform = platform ?? defaultTargetPlatform;
    final ThemeSeeds seeds = definition.seedsFor(brightness);
    final _ModeRecipe recipe = _ModeRecipe.of(brightness);
    final Color background = seeds.background.color;
    final Color surface = seeds.surface.color;
    final Color primary = seeds.accentPrimary.color;
    final Color secondary = seeds.accentSecondary.color;
    final Color onSurface = _readableForeground(
      preferred: seeds.text.color,
      background: surface,
      minimumContrast: 4.5,
    );
    final Color onPrimary = _readableForeground(
      preferred: recipe.onAccent,
      background: primary,
      minimumContrast: 4.5,
    );
    final Color onSecondary = _readableForeground(
      preferred: recipe.onAccent,
      background: secondary,
      minimumContrast: 4.5,
    );
    final Color error = _readableForeground(
      preferred: seeds.danger.color,
      background: surface,
      minimumContrast: 4.5,
    );
    final Color focusRing = _readableForeground(
      preferred: primary,
      background: surface,
      minimumContrast: 3,
    );
    final Color surfaceSoft = Color.lerp(surface, onSurface, 0.04)!;
    final Color surfaceStrong = Color.lerp(surface, onSurface, recipe.strong)!;
    final Color surfaceHighest = Color.lerp(
      surface,
      onSurface,
      recipe.strong + 0.04,
    )!;
    final Color outlineSubtle = Color.lerp(surface, onSurface, recipe.line)!;
    final Color outline = _minimumContrastBlend(
      background: surface,
      foreground: onSurface,
      minimumContrast: 3,
    );
    // Secondary label gray, pushed as far toward the surface as readability
    // allows so hierarchy reads like Apple's label / secondaryLabel pair.
    final Color mutedText = _furthestReadableBlend(
      foreground: onSurface,
      background: surface,
      maximumBlend: recipe.muted,
      minimumContrast: 4.6,
    );
    // Accent used for text and glyphs (links, selected tabs, plain buttons).
    final Color tint = _accentForText(
      accent: primary,
      toward: onSurface,
      background: surfaceStrong,
    );
    final Color shadowColor = recipe.shadow;
    final Color weakHoverOverlay = onSurface.withValues(alpha: 0.04);
    final Color hoverOverlay = onSurface.withValues(alpha: 0.09);
    final Color pressedOverlay = onSurface.withValues(alpha: 0.13);
    final Color primaryContainer = Color.lerp(
      surface,
      primary,
      recipe.accentSoft,
    )!;
    final Color secondaryContainer = Color.lerp(
      surface,
      secondary,
      recipe.accentSoft,
    )!;
    final Color errorContainer = Color.lerp(surface, error, recipe.dangerSoft)!;
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: _readableForeground(
        preferred: onSurface,
        background: primaryContainer,
        minimumContrast: 4.5,
      ),
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: _readableForeground(
        preferred: Color.lerp(secondary, onSurface, 0.35)!,
        background: secondaryContainer,
        minimumContrast: 4.5,
      ),
      error: error,
      onError: _readableForeground(
        preferred: recipe.onAccent,
        background: error,
        minimumContrast: 4.5,
      ),
      errorContainer: errorContainer,
      onErrorContainer: _readableForeground(
        preferred: onSurface,
        background: errorContainer,
        minimumContrast: 4.5,
      ),
      surface: surface,
      onSurface: onSurface,
      surfaceDim: background,
      surfaceBright: surfaceHighest,
      surfaceContainerLowest: background,
      surfaceContainerLow: surfaceSoft,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceStrong,
      surfaceContainerHighest: surfaceHighest,
      onSurfaceVariant: mutedText,
      outline: outline,
      outlineVariant: outlineSubtle,
      shadow: shadowColor,
      scrim: recipe.scrim,
      surfaceTint: Colors.transparent,
    );
    final ClockRhythmThemeExtension extension = ClockRhythmThemeExtension(
      surfaceStrong: surfaceStrong,
      surfaceSoft: surfaceSoft,
      mutedText: mutedText,
      accentSecondary: secondary,
      focusRing: focusRing,
      danger: error,
      sourceText: seeds.text.color,
      outlineSubtle: outlineSubtle,
      hoverOverlay: hoverOverlay,
      pressedOverlay: pressedOverlay,
      tint: tint,
    );
    final TextTheme textTheme = ClockRhythmTypography.build(
      platform: resolvedPlatform,
      textColor: onSurface,
      mutedTextColor: mutedText,
    );
    final RoundedRectangleBorder controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
    );
    final Color fieldFill = Color.lerp(background, surface, 0.5)!;
    final Size minimumButtonSize = const Size(
      ClockRhythmLayout.minimumInteractiveDimension,
      ClockRhythmLayout.minimumInteractiveDimension,
    );
    final WidgetStateProperty<Color?> interactiveOverlay =
        WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.pressed)) {
            return pressedOverlay;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return hoverOverlay;
          }
          return null;
        });
    final ButtonStyle controlButtonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(minimumButtonSize),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: ClockRhythmSpace.space16,
          vertical: ClockRhythmSpace.space12,
        ),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(controlShape),
      overlayColor: interactiveOverlay,
      elevation: const WidgetStatePropertyAll<double>(0),
      shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
      animationDuration: ClockRhythmMotion.standard,
    );
    final Color disabledFill = onSurface.withValues(alpha: 0.06);
    final Color disabledForeground = mutedText.withValues(alpha: 0.5);
    final OutlineInputBorder fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
      borderSide: BorderSide(color: outlineSubtle),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      platform: resolvedPlatform,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      focusColor: focusRing,
      hoverColor: weakHoverOverlay,
      highlightColor: hoverOverlay,
      splashColor: pressedOverlay,
      splashFactory: NoSplash.splashFactory,
      shadowColor: shadowColor,
      dividerColor: outlineSubtle,
      disabledColor: mutedText.withValues(alpha: 0.48),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClockRhythmRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineSubtle,
        thickness: 1,
        space: 1,
      ),
      // Filled: the one prominent action per area, in the primary accent.
      filledButtonTheme: FilledButtonThemeData(style: controlButtonStyle),
      // Outlined: a ghost button — transparent fill and a hairline stroke
      // that turns into the focus ring when focused.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: controlButtonStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.disabled)
                ? disabledFill
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.disabled)
                ? disabledForeground
                : onSurface;
          }),
          iconColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.disabled)
                ? disabledForeground
                : onSurface;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: focusRing, width: 2);
            }
            return BorderSide(color: outline);
          }),
        ),
      ),
      // Text: a plain tinted label.
      textButtonTheme: TextButtonThemeData(
        style: controlButtonStyle.copyWith(
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: ClockRhythmSpace.space12),
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.disabled)
                ? disabledForeground
                : tint;
          }),
          iconColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.disabled)
                ? disabledForeground
                : tint;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size.square(ClockRhythmLayout.minimumInteractiveDimension),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(controlShape),
          overlayColor: interactiveOverlay,
          animationDuration: ClockRhythmMotion.standard,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: controlButtonStyle.copyWith(
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: ClockRhythmSpace.space16),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(controlShape),
          side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: outline)),
          // A chosen segment reads as selection, which the app marks with
          // the primary accent everywhere, not the secondary one.
          backgroundColor:
              WidgetStateProperty.fromMap(<WidgetStatesConstraint, Color>{
                WidgetState.selected: colorScheme.primaryContainer,
                WidgetState.any: Colors.transparent,
              }),
          foregroundColor:
              WidgetStateProperty.fromMap(<WidgetStatesConstraint, Color>{
                WidgetState.disabled: colorScheme.onSurfaceVariant,
                WidgetState.selected: colorScheme.onPrimaryContainer,
                WidgetState.any: colorScheme.onSurface,
              }),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: fieldFill,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ClockRhythmSpace.space16,
          vertical: ClockRhythmSpace.space12,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: focusRing, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: mutedText),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((
          Set<WidgetState> states,
        ) {
          final Color color = states.contains(WidgetState.error)
              ? error
              : states.contains(WidgetState.focused)
              ? tint
              : mutedText;
          return textTheme.bodyMedium!.copyWith(color: color);
        }),
        hintStyle: textTheme.bodyMedium?.copyWith(color: mutedText),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: error),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowColor,
        elevation: 0,
        insetPadding: const EdgeInsets.all(ClockRhythmSpace.space24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClockRhythmRadius.dialog),
          side: BorderSide(color: outlineSubtle),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      // On phones a dialog becomes a sheet attached to the bottom edge, on
      // the same surface as a dialog.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ClockRhythmRadius.dialog),
          ),
          side: BorderSide(color: outlineSubtle),
        ),
      ),
      // A quiet tab bar whose selected glyph sits in a tinted pill.
      navigationBarTheme: NavigationBarThemeData(
        height: ClockRhythmLayout.androidNavigationHeight,
        backgroundColor: fieldFill,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryContainer,
        indicatorShape: const StadiumBorder(),
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
          Set<WidgetState> states,
        ) {
          return IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? tint : mutedText,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? onSurface : mutedText,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: ClockRhythmSpace.space8,
        minTileHeight: ClockRhythmLayout.minimumInteractiveDimension,
        iconColor: mutedText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
        ),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        // A non-null icon keeps the thumb full size in both states, like iOS.
        thumbIcon: const WidgetStatePropertyAll<Icon>(Icon(null)),
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.disabled)
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          final Color color = selected ? secondary : surfaceHighest;
          return states.contains(WidgetState.disabled)
              ? color.withValues(alpha: 0.4)
              : color;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        overlayColor: interactiveOverlay,
      ),
      // Small rounded-square completion marks.
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: outline, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (!states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return states.contains(WidgetState.disabled)
              ? primary.withValues(alpha: 0.4)
              : primary;
        }),
        checkColor: WidgetStatePropertyAll<Color>(onPrimary),
        overlayColor: interactiveOverlay,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: ClockRhythmSpace.space4,
        activeTrackColor: primary,
        inactiveTrackColor: surfaceHighest,
        thumbColor: Colors.white,
        overlayColor: hoverOverlay,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 2,
          pressedElevation: 4,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: ClockRhythmSpace.space20,
        ),
        valueIndicatorColor: surfaceHighest,
        valueIndicatorTextStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tint,
        linearTrackColor: surfaceHighest,
        linearMinHeight: 4,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHighest,
        contentTextStyle: textTheme.bodyMedium,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll<double>(6),
        radius: const Radius.circular(ClockRhythmRadius.pill),
        thumbColor: WidgetStatePropertyAll<Color>(
          onSurface.withValues(alpha: 0.28),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceHighest,
          borderRadius: BorderRadius.circular(ClockRhythmRadius.small),
        ),
        textStyle: textTheme.labelSmall?.copyWith(color: onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: ClockRhythmSpace.space12,
          vertical: ClockRhythmSpace.space8,
        ),
        waitDuration: ClockRhythmMotion.standard,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClockRhythmRadius.dialog),
        ),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
        ),
        dialBackgroundColor: surfaceStrong,
      ),
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

  /// Moves an accent toward [toward] only as far as needed for text-level
  /// contrast on [background], keeping its hue recognisable.
  static Color _accentForText({
    required Color accent,
    required Color toward,
    required Color background,
  }) {
    if (_contrast(accent, background) >= 4.5) {
      return accent;
    }
    for (int step = 1; step <= 20; step += 1) {
      final Color candidate = Color.lerp(accent, toward, step / 20)!;
      if (_contrast(candidate, background) >= 4.5) {
        return candidate;
      }
    }
    return toward;
  }

  static Color _furthestReadableBlend({
    required Color foreground,
    required Color background,
    required double maximumBlend,
    required double minimumContrast,
  }) {
    double lower = 0;
    double upper = maximumBlend;
    final Color furthest = Color.lerp(foreground, background, upper)!;
    if (_contrast(furthest, background) >= minimumContrast) {
      return furthest;
    }
    for (int iteration = 0; iteration < 12; iteration += 1) {
      final double midpoint = (lower + upper) / 2;
      final Color candidate = Color.lerp(foreground, background, midpoint)!;
      if (_contrast(candidate, background) >= minimumContrast) {
        lower = midpoint;
      } else {
        upper = midpoint;
      }
    }
    return Color.lerp(foreground, background, lower)!;
  }

  static Color _minimumContrastBlend({
    required Color background,
    required Color foreground,
    required double minimumContrast,
  }) {
    double lower = 0;
    double upper = 1;
    for (int iteration = 0; iteration < 12; iteration += 1) {
      final double midpoint = (lower + upper) / 2;
      final Color candidate = Color.lerp(background, foreground, midpoint)!;
      if (_contrast(candidate, background) >= minimumContrast) {
        upper = midpoint;
      } else {
        lower = midpoint;
      }
    }
    return Color.lerp(background, foreground, upper)!;
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

/// The mixing ratios each appearance mode uses to derive roles from a
/// palette's seeds. Light mode mixes differently because the dark-mode
/// ratios leave muted text and tinted fills under 4.5:1 on light grounds.
final class _ModeRecipe {
  const _ModeRecipe({
    required this.strong,
    required this.line,
    required this.muted,
    required this.accentSoft,
    required this.dangerSoft,
    required this.onAccent,
    required this.scrim,
    required this.shadow,
  });

  factory _ModeRecipe.of(Brightness brightness) {
    return switch (brightness) {
      Brightness.dark => _dark,
      Brightness.light => _light,
    };
  }

  static const _ModeRecipe _dark = _ModeRecipe(
    strong: 0.09,
    line: 0.09,
    muted: 0.38,
    accentSoft: 0.20,
    dangerSoft: 0.16,
    onAccent: Color(0xFF000000),
    scrim: Color(0xA3000000),
    shadow: Color(0x99000000),
  );

  static const _ModeRecipe _light = _ModeRecipe(
    strong: 0.07,
    line: 0.11,
    muted: 0.30,
    accentSoft: 0.12,
    dangerSoft: 0.10,
    onAccent: Color(0xFFFFFFFF),
    scrim: Color(0x660A0B0E),
    shadow: Color(0x240A0B0E),
  );

  /// Surface mixed toward text for selected and disabled fills.
  final double strong;

  /// Surface mixed toward text for hairline dividers and borders.
  final double line;

  /// The furthest text may be mixed toward the surface for secondary text.
  final double muted;

  /// Surface mixed toward an accent for tinted fills.
  final double accentSoft;

  /// Surface mixed toward danger for error fills.
  final double dangerSoft;

  /// The preferred foreground on accent and danger fills.
  final Color onAccent;
  final Color scrim;
  final Color shadow;
}
