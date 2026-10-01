# Flutter design-system translation specification

## Overview

- Target files: `lib/shared/ui/design_tokens.dart`, `lib/contexts/preferences/presentation/theme/clock_rhythm_theme.dart`, `lib/shared/ui/clock_rhythm_card.dart`, platform navigation, and existing presentation consumers.
- Screenshot: source captures were inspected in-session; persistent screenshots are evidence-only and are not shipped.
- Source URL: `https://www.tossinvest.com/?focusedProductCode=A000660`.
- Selector: N/A — this specification translates a cross-page token system rather than one DOM subtree.
- Interaction model: static token foundation plus hover, focus, press, selection, and theme-mode states.

## DOM Structure

N/A for direct porting. The observed source hierarchy is top navigation -> market summary -> tab and
filters -> dense table -> detail panel -> side rails -> bottom ticker. Clock Rhythm keeps its Flutter
semantic and widget trees and transfers only token relationships.

## Computed Styles

| Source role | Exact observed value |
| --- | --- |
| Dark screen/background/layer 1/layer 2 | `#101013` / `#17171C` / `#202025` / `#2C2C35` |
| Dark primary/secondary/tertiary text | `rgba(242,246,255,0.90)` / `rgba(217,223,235,0.80)` / `rgba(211,224,243,0.42)` |
| Brand icon/text | `#3182F6` / `#4391FF` |
| Standard/weak hover and pressed | `rgba(214,224,239,0.09)` / `rgba(218,223,233,0.04)` / `rgba(213,223,244,0.13)` |
| Common font sizes | 12, 13, 14, 16 pixels |
| Common weights | 400, 500, 600, 700 |
| Common line heights | 16, 20, 23.2 pixels |
| Common radii | 4, 7, 8, 10, 999 pixels |
| Navigation and dense row heights | 52 and 44 pixels |
| Interaction transition | 200ms, mostly `ease` |

## States and Behaviors

- Trigger: pointer hover. State A is transparent or weak fill; state B uses the semantic 4% or 9%
  foreground overlay over 200ms.
- Trigger: press. State B uses the semantic 13% foreground overlay while the command owner remains
  unchanged.
- Trigger: keyboard focus. State B shows a 3:1 minimum-contrast focus outline without changing layout.
- Trigger: destination selection. State B uses stronger text, primary accent, and a visible indicator.
- Trigger: reduced-motion preference. All app-owned durations resolve to zero and final states remain.

## Per-State Content

No content is transferred. Existing localized Clock Rhythm labels, values, errors, and state copy
remain authoritative in every state.

## Assets

N/A — no source image, logo, SVG, video, font, mask, or poster is transferred. Existing Material
icons and Clock Rhythm assets remain authoritative.

## Text Content

N/A — source copy and market data are excluded. Existing ARB localization catalogs own app text.

## Responsive Behavior

- Desktop source at 1440 x 900: dense multi-pane workspace with fixed top and bottom layers.
- Tablet sample at 768: not an implementation authority for Flutter.
- Mobile source at 390 x 844: retains 1024-pixel width and horizontally overflows.
- Flutter decision: preserve constraint-driven compact/wide layouts, Android safe areas and bottom
  navigation, Windows minimum 720 x 560, and 200-percent text adaptation.

## Original Implementation Inventory

- DOM subtree: not ported.
- CSS blocks and custom properties: inspected to extract semantic values; not copied.
- JavaScript drivers/listeners/keyframes/timers: not ported.
- Masks, canvas, charts, layers, z-index: not ported.
- Third-party libraries: none added.

## Parity Decision

`approved reimplementation` for visual-token translation. Direct DOM/CSS/JS or framework-adapted
porting would violate the Flutter platform boundary and transfer unrelated financial-product layout
and behavior. The approved fidelity target is token hierarchy, density, radius, panel treatment, and
motion character, explicitly adapted for Flutter accessibility and platform conventions.

