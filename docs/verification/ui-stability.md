# Todo editing and stable control layout

## Behavior

- Clock and Calendar creation returns focus to the same title field after a successful save, unless the user has moved to another input or destination.
- Clicking a Todo title edits it in place. Enter or leaving the field saves; Escape or Android Back cancels. Korean composition does not submit early.
- Details open in a Windows dialog or Android bottom sheet. Dates and times retain the existing pickers. Closing returns focus to the originating details control, or the composer when rescheduling removes that row.
- Settings status, Todo feedback, sound controls, rhythm actions, optional-time controls, and import progress reserve their state-dependent space.
- Sound choices have consistent button dimensions and expose their selected/toggled states with their labels.
- Todo creation uses a full-width title input at every screen width, with time/add controls right-aligned below it. The hidden time-clear slot precedes the time control so it does not create a gap between time and add. Sound actions divide the available width equally and always occupy one row without horizontal scrolling. At narrower widths, icons sit above wrapping labels; the longest state label determines the shared height before interaction.

## Verification

Verified with Flutter 3.44.7 / Dart 3.12.2 on 2026-10-03:

- Full Flutter suite after centering the rhythm input values: 627 passed, including the four PowerShell quality-gate tests that failed in the previous environment.
- Android API 36 emulator before the responsive action update: 19 interaction tests passed through `integration_test/ui_stability_test.dart`, using an in-memory repository rather than user data. The latest layout changes were covered by widget tests, not rerun on the emulator.
- Text/layout matrix: Korean and English, widths 360/390/720/1280, and text scales 100%/200%. Existing 11-theme contrast checks passed.
- The sound-action matrix covers Windows' four buttons and Android's three supported buttons, preview/stop, MP3/default selection, and mute/unmute. It verifies equal sizes, a single visible row, unchanged bounds between states, and no horizontal scrollable. Todo checks cover both creation variants and time selection/clearing.
- Static analysis, formatting, architectural boundaries, documentation links, and generated-output checks passed.
- Windows Beta release compiled. Native autostart and launch/hide/reopen/duplicate-launch checks passed.
- Windows rendering inspected at wide and 720×560 window sizes. The autostart draft was toggled and restored without changing the saved setting; the settings card and following controls kept their positions.
- After the responsive action update, the rebuilt Windows app was inspected at its restored narrow window size. All four sound buttons were visible on one row; starting preview changed the label/icon without shifting or resizing the controls. Saved settings were not changed.
- After removing the inline creation layout, both Clock and Calendar were inspected in the rebuilt Windows app: the title input spans the card, with time and add adjacent at its lower right. The full 626-test suite, static analysis, and architectural checks passed again.
- Focus/rest durations and daily start/end values are centered in their full input boxes, with labels and picker buttons unchanged. Korean/English widget checks cover 360/720/1280 widths; the rebuilt Windows Settings screen was visually verified without changing saved values.
- Two changed golden baselines were reviewed and regenerated; the other two remained unchanged.

The FVM launcher was not available on the current process PATH. Commands used the repository's existing `.fvm/flutter_sdk/bin` executables directly. Locked dependency resolution, localization generation, and build_runner regeneration left all tracked generated files unchanged.

Run the focused device suite with:

```powershell
& '.fvm/flutter_sdk/bin/flutter.bat' test integration_test/ui_stability_test.dart -d emulator-5554 --flavor beta --dart-define=CLOCK_RHYTHM_FLAVOR=beta --no-pub
```

Real mobile keyboards may scroll the page to reveal the caret. Device tests compare row size and action positions relative to the row; unit tests also assert unchanged screen bounds when the viewport is unchanged.

Native Android IME composition and physical Back gestures beyond Flutter's integration-test input remain separate manual-device checks. No production signing or installer publication was performed.
