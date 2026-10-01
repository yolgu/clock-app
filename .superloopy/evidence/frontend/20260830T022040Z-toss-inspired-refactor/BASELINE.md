# Baseline evidence

## Target and build context

- Repository: Clock Rhythm Flutter app.
- Supported targets: Windows 10/11 x64 and Android API 24+.
- Flutter: 3.44.7 stable.
- Dart: 3.12.2.
- Host: Windows 11 25H2.
- Current actual device availability: Windows desktop; no Android device connected.

## Source reference

- URL: `https://www.tossinvest.com/?focusedProductCode=A000660`.
- Browser: Chrome 151.
- Inspected source viewports: default 3440 x 1271, desktop 1440 x 900, narrow 390 x 844.
- Source dark and light semantic tokens, topology, and responsive limitation are recorded under
  `docs/research/www.tossinvest.com/`.

## Worktree baseline

The worktree contained user-owned, uncommitted changes across shared design tokens, theme,
presentation widgets, accessibility support, tests, and golden images before this refactor began.
Those changes are the implementation baseline and must not be reset, checked out, or overwritten.

## Baseline command

`fvm flutter test test/shared/ui/design_tokens_test.dart test/contexts/preferences/presentation/theme/theme_component_tokens_test.dart test/contexts/preferences/presentation/theme/theme_contrast_test.dart test/goldens/adaptive_layout_golden_test.dart`

Result: 23 tests passed before Toss-inspired token changes.

## Baseline claims

- Existing functional state owners and routes are out of scope.
- Existing focused token/theme/golden tests are green.
- Source web mobile behavior is not suitable for Flutter reuse.
- No source asset or dependency is required.

