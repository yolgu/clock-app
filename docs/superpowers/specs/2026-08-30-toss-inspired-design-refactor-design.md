# Toss-inspired Clock Rhythm design refactor

## Objective

Refactor Clock Rhythm's shared presentation system using the visual tokens observed at
`https://www.tossinvest.com/?focusedProductCode=A000660` while preserving the product's existing
behavior, platform conventions, accessibility contract, local-first architecture, and eleven stable
theme identifiers.

The source page is an approved external visual reference for palette hierarchy, density, shape,
surface treatment, and motion character only. Toss branding, copy, market data, icons, screenshots,
assets, and proprietary fonts are not implementation inputs.

## Scope

The refactor applies to the complete Flutter presentation surface on Windows 10/11 and Android API
24+. It changes shared design tokens, the default Clock Rhythm palette, component theming, cards,
Windows navigation, and the presentation widgets that currently consume those shared primitives.

The following remain unchanged:

- Riverpod state ownership and application commands.
- GoRouter destinations and navigation behavior.
- Domain rules, persistence, backup compatibility, localization keys, and user-facing capabilities.
- All eleven `ThemePreference` identifiers.
- The source swatches of the ten non-default compatibility themes.
- Windows keyboard navigation and Android 48 logical-pixel touch targets.

## Source observations

The source was inspected on 2026-08-30 in Chrome 151 at 1440 x 900 and 390 x 844. Computed styles,
root custom properties, visible states, and the light/dark mode toggle were inspected.

The desktop surface uses a 52-pixel top region, 44-pixel data rows, 4/8-pixel spacing increments,
8-pixel controls, restrained 10-pixel panels, subtle inset boundaries, and 200-millisecond state
transitions. Its dark hierarchy is based on `#101013`, `#17171C`, `#202025`, and `#2C2C35`, with
`#3182F6` as the brand accent. Its light hierarchy is based on `#F6F7F9`, `#FFFFFF`, `#F9FAFB`, and
`#F2F4F6`.

The source keeps a 1024-pixel minimum content width at a 390-pixel viewport and therefore does not
provide a valid mobile layout model. Clock Rhythm will translate the token system, not the source
page topology or responsive behavior.

## Design direction

Clock Rhythm is a monitoring and action surface. The primary job is to understand the current Daily
Rhythm state and take the next action without visual decoding. Calendar, Todo, Preferences, Theme,
and Data surfaces remain supporting journeys.

The visual thesis is a calm, precise productivity instrument: near-black layered surfaces, compact
but readable information density, blue for primary interaction, restrained outlines instead of
floating shadows, and clear typography rather than decorative effects. Motion communicates state
change and focus continuity; it is not ornament.

## Token ownership

`lib/contexts/preferences/presentation/theme/theme_catalog.dart` remains the authority for stored
theme IDs and each theme's source palette. The default `ThemePreference.current` palette changes to:

| Role | Value |
| --- | --- |
| Screen background | `#101013` |
| Primary surface | `#17171C` |
| Primary text source | `#F2F6FF` |
| Primary accent | `#3182F6` |
| Secondary accent | `#57C28D` |
| Danger | `#F5445A` |

`lib/shared/ui/design_tokens.dart` remains the authority for spacing, geometry, motion, typography,
and adaptive measurements. `ClockRhythmTheme.build` maps palette inputs into semantic Material and
`ClockRhythmThemeExtension` roles. Presentation widgets consume those semantic roles and do not
recreate palette math.

### Spatial tokens

- Spacing: 4, 8, 12, 16, 20, 24, and 32 logical pixels.
- Radius: 4 for small marks, 8 for controls, 10 for cards, 12 for dialogs, and 999 only for true
  pills or circular controls.
- Page inset: 16 below 600 pixels, 20 from 600 to 919 pixels, and at least 24 above 920 pixels while
  centering the existing 1120-pixel maximum content width.
- Card padding: 16 on compact surfaces and 20 otherwise.
- Windows navigation height: 52.
- Dense Windows row height: 44 where content and accessibility constraints permit it.
- Interactive minimum: 48 on Android and on shared controls that must satisfy both targets.

### Typography

No new font dependency is introduced. Windows uses Segoe UI and Android uses Roboto. The proprietary
Toss Product Sans family is not copied or bundled.

- Display roles remain 48/56, 40/48, and 32/40 for the clock and exceptional numeric emphasis.
- Headlines use 30/38, 24/32, and 20/28 with weight 600.
- Titles use 18/26, 16/24, and 14/20 with weight 600.
- Body roles use 16/24, 14/20, and 13/20 with weight 400.
- Labels use 14/20, 13/18, and 12/16 with weight 600 where emphasis is required.
- Text scaling remains supported to 200 percent; compact layouts take precedence when enlarged text
  would make a wide composition unsafe.

### Color derivation

All themes derive the same semantic hierarchy from their own source swatches:

- Weak surface: 4 percent foreground blend.
- Strong surface and subtle panel boundary: 9 percent foreground blend.
- Highest surface and pressed overlay: 13 percent foreground blend.
- Hover overlay: 4 percent on weak affordances and 9 percent on standard affordances.
- Primary weak fill: 20 percent primary blend.
- Focus and control outlines retain at least 3:1 contrast where they communicate component state.
- Text roles retain at least 4.5:1 contrast against their owning surface.

The source page's finance-specific red-positive and blue-negative meanings are not transferred.
Clock Rhythm keeps red for danger or failure and uses product-domain semantics for all other states.

### Motion

- Fast feedback: 100 milliseconds.
- Standard hover, press, focus, and selection transition: 200 milliseconds.
- Deliberate route or panel transition, only where already justified: 300 milliseconds.
- The standard curve is ease-out for entry and ease for reversible state feedback.
- `disableAnimations` and `accessibleNavigation` reduce app-owned motion to zero while preserving
  the final state, semantics, and focus.

## Component changes

### Theme foundation

`ClockRhythmTheme.build` will provide one component contract for cards, buttons, inputs, dialogs,
navigation, list rows, checkboxes, sliders, and tooltips. General buttons use the 8-pixel control
radius. Only segmented filters, chips, and circular icon affordances use the pill radius.

`ClockRhythmThemeExtension` will continue to expose only semantic roles that Material's
`ColorScheme` cannot express clearly. Derived values remain centralized and testable.

### Cards and panels

`ClockRhythmCard` becomes a flat panel with a 10-pixel radius and subtle boundary. The current large
drop shadow is removed. Padding remains explicit through the existing padded and unpadded
constructors so each panel keeps one clear spatial owner.

### Windows navigation

`WindowsTopNavigation` becomes a 52-pixel horizontal tab strip. Each destination remains a real
button with selected semantics, visible focus, arrow-key navigation, and the existing destination
callback. Selection is shown with stronger text, a blue indicator, and a restrained hover/pressed
surface rather than one large segmented pill.

### Android navigation

`AndroidBottomNavigation` retains Material `NavigationBar`, native back behavior, and 48-pixel target
guidance. Its background, indicator, icon, and label states are mapped to the shared semantic tokens.
It does not copy the source site's desktop side rail.

### Feature surfaces

Clock, Rhythm, Today Todo, Calendar, Preferences, Theme, Data, recovery, and error surfaces keep
their current responsibilities and state owners. They inherit the revised theme and card contract.
Local changes are limited to remaining literal geometry or component structures that prevent the
shared tokens from taking effect.

## Layout and behavior invariants

- Windows preserves top navigation; Android preserves bottom navigation.
- Existing compact/wide content composition remains constraint-driven.
- No source-page minimum width or horizontal overflow is introduced.
- Route content, scroll restoration, form drafts, focus order, and state ownership remain unchanged.
- Long Korean and English text, 200-percent scaling, keyboard focus, TalkBack/Narrator semantics,
  and Android target size remain completion criteria.
- Decoration has no semantics or focus stop.

## Verification

Implementation will be verified in this order:

1. Format all changed Dart files.
2. Run token, theme-component, theme-contrast, shared-card, navigation, and affected widget tests.
3. Run accessibility contrast, target-size, focus-order, semantics, and text-scale tests.
4. Regenerate and inspect compact Android and wide Windows golden baselines, including representative
   Calendar and non-default-theme states.
5. Run `flutter analyze` and the complete Flutter test suite through the repository's FVM toolchain.
6. Build and launch the Windows target, inspect the main journeys at the minimum and representative
   window sizes, and capture visual evidence.
7. Build or run the Android target on an available supported emulator, inspect portrait and resized
   layouts, and record any physical-device-only gap explicitly.

Visual comparison checks hierarchy, density, spacing, typography, radii, surfaces, hover/focus/
selected states, overflow, localization, and reduced-motion behavior. Screenshots prove rendering
only; widget, accessibility, and interaction evidence prove their respective contracts.

## Delivery artifacts

The implementation will retain the source research under `docs/research/www.tossinvest.com/` and
store run-scoped screenshots, validation output, and `VISUAL_QA.md` under
the timestamped `.superloopy/evidence/frontend/` run directory created at implementation start. No
source-site asset or proprietary font will be added to the application.
