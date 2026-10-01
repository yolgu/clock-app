# Toss-inspired refactor visual QA

## Decision

- Windows visual findings: 0 open
- Golden findings: 0 open
- Android real-device rendering: unverified because no emulator or physical device was connected
- Result: accepted for the requested Windows implementation and Android build scope

## Reference authority

The Toss Securities page is the approved source for color hierarchy, spacing rhythm, radii, flat surfaces, typography density, and 200ms state motion. Its brand, assets, proprietary font, financial content, fixed-width web layout, and responsive behavior are intentionally excluded. Clock Rhythm's routes, copy, feature states, Windows navigation ownership, and Android navigation ownership remain authoritative.

## Windows rendered checks

| Surface and state | Target | Result | Evidence |
| --- | --- | --- | --- |
| Clock, default Clock Rhythm palette | Windows beta release, minimum 720×560 outer bounds | 52px inline navigation, selected underline, flat status panel, primary action, and vertical scroll remain visible without horizontal overflow. | `windows-default-clock-720x560.png` |
| Calendar, default Clock Rhythm palette | Windows beta release, minimum 720×560 outer bounds | Compact calendar remains readable; date grid keeps selection and today borders; overflow is vertical only. | `windows-default-calendar-720x560.png` |
| Theme, default selected | Windows beta release, minimum 720×560 outer bounds | Current palette is selected; source swatches, selected border, flat cards, and two-column adaptation remain intact. | `windows-default-theme-720x560.png` |
| Clock, representative tall window | Windows beta release, 720px outer width | Clock, status, controls, Today panel, settings, and sound panel keep the same token hierarchy and scroll owner. | Live Windows capture inspected during the run; the minimum-bound evidence above is retained as the stricter geometry case. |

The capture API reported a 706×560 image for the app's minimum window. The native persisted placement reported 720px outer width at 96 DPI; the difference is non-client framing.

## Interaction and accessibility checks

- Pointer navigation switched Clock, Calendar, and Theme in the release build.
- Calendar exposed 42 date cells and selected/today state in the Windows accessibility tree.
- Theme selection exposed the current and all compatibility themes; the original beta preference was restored after inspection.
- Widget semantics assert four independent button labels, selected state, and traversal descendants.
- Widget interaction tests assert arrow-key clamping, destination focus movement, visible focus styling, click callback behavior, Ctrl+1–4 routing, and 200% text at 720×560.
- Computer Use's Windows tree exposed body controls but omitted the fixed top-navigation subtree even after the implementation used standard `TextButton` semantics. Because Flutter's final semantics tree and keyboard tests pass while this external bridge remains inconclusive, native assistive-technology exposure of that subtree is not promoted beyond automated semantics evidence.

## Golden inspection

- Compact Korean Calendar at 200% text: no horizontal clipping; vertically scrollable content is preserved.
- Wide English Calendar in Neon Dusk: calendar and selected-day panel preserve hierarchy and non-default palette compatibility.
- Wide Windows Clock in the current palette: selected tab, analog/digital clock, flat panels, controls, and settings hierarchy are intact.
- Compact Android Theme in Korean: current palette, compatibility cards, selected state, and bottom navigation remain intact.

Every updated PNG was inspected at original resolution after regeneration. Expected red-phase mismatch diagnostics are preserved under `golden-red-phase-diagnostics/`.

## Intentional differences from the reference

- Uses Segoe UI and Roboto instead of source fonts.
- Uses Clock Rhythm content, routes, controls, and platform navigation.
- Preserves Android 48dp targets and responsive Flutter layouts instead of the source page's horizontal overflow at 390px.
- Preserves ten non-default theme source swatches while applying the Toss-inspired palette only to the default theme.

## Remaining limitations

- No Android device screenshot or physical-device accessibility pass is available in this run.
- No user study was performed; this evidence establishes implementation fidelity and automated interaction contracts, not user preference or task-success prevalence.
