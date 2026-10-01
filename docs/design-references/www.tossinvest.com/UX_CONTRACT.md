# Clock Rhythm Toss-inspired visual refactor UX contract

## Baseline and delta

- Primary users: Windows 10/11 keyboard-and-pointer users and Android API 24+ touch users.
- Primary job: perceive the current Daily Rhythm state and invoke the next valid action.
- Affected journeys: every presentation surface through theme, card, spacing, type, and navigation.
- Adjacent regression journeys: Todo editing/reordering, Calendar selection, settings draft, sound
  preview, data import/export, recovery, route back behavior.
- Baseline evidence: current user-owned uncommitted design-system work; focused token, theme,
  contrast, and golden suite passes 23 tests.
- Desired delta: Toss-inspired density, neutral layering, blue primary emphasis, smaller radii,
  flat panels, and 200ms interaction feedback.

## User coverage

| Population / context | Evidence status | Impact and success measure |
| --- | --- | --- |
| Windows pointer and keyboard users | Repository contracts and widget tests; high confidence | Four destinations, core actions, and focus remain reachable at 720 x 560 and representative bounds |
| Android touch users | Repository contracts; build available; current device unavailable | Core actions retain at least 48 logical pixels and bottom navigation/back behavior |
| Korean and English users | Existing localization and goldens; high confidence | No changed or hardcoded copy; long labels do not clip |
| 200-percent text users | Existing adaptive and accessibility tests; high confidence | Wide layouts collapse before content becomes unsafe; actions remain reachable |
| TalkBack/Narrator users | Existing semantics tests; target manual evidence pending | Names, roles, selected state, focus order, and status announcements remain truthful |

## Spatial ownership

- Platform shell owns top navigation on Windows and bottom navigation on Android.
- Each route owns its vertical page scroll and restoration key.
- `AdaptiveContentLayout` owns compact/wide composition from actual constraints and text scale.
- `ClockRhythmCard` owns panel boundary, radius, clipping, and optional internal padding.
- Feature widgets own content order and local control placement.
- No source-page fixed rail, ticker, minimum width, or horizontal overflow transfers to Clock Rhythm.

## Capability and state contract

| Capability | Owner | States preserved | Evidence |
| --- | --- | --- | --- |
| Main destination selection | App shell and platform navigation | idle, hovered, focused, pressed, selected | widget, focus-order, actual Windows interaction |
| Rhythm commands | Rhythm ViewModel and controls | idle, running, paused, stopped, unavailable/error | existing widget and ViewModel tests |
| Todo editing | Todo ViewModel and editor | display, editing, validation, save, cancel, failure | existing widget tests |
| Calendar selection | Todo ViewModel and Calendar widgets | month, selected date, empty/populated date | widget, text-scale, golden |
| Preferences draft | Preferences ViewModel and settings form | pristine, dirty, validation, save, discard, repair | existing widget tests |
| Theme selection | Preferences command and ThemeCatalog | selected and unselected for all 11 IDs | catalog, widget, golden |
| Data transfer | Data-transfer ViewModel and dialogs | idle, preview, running, success, failure | existing presentation tests |

## Invariants

- A visible enabled affordance invokes the same production command as before the refactor.
- Selection, success, failure, and danger are not communicated by color alone.
- Every interactive Android control keeps a 48 logical-pixel target.
- Focus remains visible and follows semantic/reading order.
- Reduced motion removes app-owned duration without removing state or feedback.
- No route, state owner, data boundary, persistence value, or localized string changes.
- Default theme ID remains `current`; ten non-default source palettes remain byte-for-byte equal.

## Traceability

| Contract | Implementation owner | Automated evidence | Rendered evidence |
| --- | --- | --- | --- |
| Approved token scale | `shared/ui/design_tokens.dart` | token tests | Windows/Android goldens |
| Compatible palette mapping | `theme_catalog.dart`, `clock_rhythm_theme.dart` | catalog and contrast tests | Theme page golden |
| Flat panel contract | `shared/ui/clock_rhythm_card.dart` | shared widget test | Clock/Calendar captures |
| Windows inline navigation | `windows_top_navigation.dart` | navigation and focus tests | Windows capture and keyboard sweep |
| Android native navigation | `android_bottom_navigation.dart`, Material theme | app shell and target-size tests | Android golden; device evidence if available |
| Adaptive content | page and `AdaptiveContentLayout` owners | text-scale and widget tests | compact/wide goldens |

## Failure and recovery

- Theme or geometry regressions fail focused tests before golden approval.
- A clipped or overlapping rendered state remains an open visual finding and blocks completion.
- Android device absence limits only real-device rendering claims; APK build and automated
  accessibility contracts remain independently reportable.
- Existing user changes are never reset to recover from a failure; the failed feature slice is fixed
  or reverted with an explicit file-level patch.

## Privacy and assets

The refactor reads no account data and sends no user data. Toss marks, source screenshots, company
logos, proprietary fonts, market data, and source code are excluded from the shipped app.

