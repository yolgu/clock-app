# TalkBack and Narrator manual evidence checklist

Run this checklist against the exact release artifact recorded in `artifacts/manifest.json`. Automated semantics, target-size, contrast, keyboard, text-scale, and golden tests are prerequisites; they do not replace assistive-technology observation.

## Evidence header

Record one header per platform run. Do not record Todo titles, custom-sound paths, device serials, account data, or credentials.

| Field | Value |
| --- | --- |
| Date/time and time zone | `<ISO-8601 timestamp>` |
| Artifact basename and SHA-256 | `<artifact> / <sha256>` |
| Flavor and package identity | `<beta-or-production identity>` |
| OS/API and device class | `<Windows build or Android API; phone/tablet>` |
| Assistive technology and version | `<Narrator or TalkBack version>` |
| Locale, theme, text scale | `<ko-or-en / theme / scale>` |
| Input method | `<keyboard / touch exploration / switch access if used>` |
| Result | `Passed / Failed / Blocked` |
| Redacted evidence reference | `<external evidence ID>` |

## Android TalkBack

Test a phone and tablet where available, including portrait, landscape, and split-screen. Repeat the highest-risk flow at 200-percent text.

| Flow | Required observation | Result |
| --- | --- | --- |
| Clock reading order | Destination navigation, digital time, Rhythm status, valid controls, Today Todos, Rhythm Settings, and sound/permission controls are reached in visual order. The analog clock is skipped. | Pending |
| Clock announcements | Start, Pause, Resume, Stop for Today, import completion, and errors announce once. The one-second clock tick never becomes a live announcement. | Pending |
| Explicit Start permission | The first Start explains and requests only the required notification/exact-alarm access. Denial leaves Rhythm Idle; granting access alone does not start it. | Pending |
| Rhythm Settings | Summary, unsaved/invalid/outside-window/zero-volume/deep-idle warnings, HH:mm fields, picker, Save, and Discard have localized roles and state. | Pending |
| Today Todo | Title error appears only after interaction; add, time picker, completion, edit, reorder, and delete are independently operable and expose state without color alone. | Pending |
| Calendar | Month heading, previous/next/Today, each selectable date, Todo counts, today, and selection are announced without reading blank adjacency cells. | Pending |
| Data Transfer | Export warning and import preview move focus into the dialog, expose redacted counts/settings, and return focus after Cancel/Confirm. Android Back cancels the top dialog before leaving the destination. | Pending |
| Theme | All eleven choices expose localized names and selected state; selection is not conveyed by color alone. | Pending |
| Layout variants | No primary action, error, label, or focused control is clipped or trapped in portrait, landscape, split-screen, or 200-percent text. | Pending |

## Windows Narrator and keyboard

Test Windows 10 and Windows 11 with the installed or portable artifact required by the release matrix. Use keyboard only for one complete pass.

| Flow | Required observation | Result |
| --- | --- | --- |
| Main destinations | `Ctrl+1` through `Ctrl+4`, Tab/Shift+Tab, and segmented-control arrows select Clock, Calendar, Data, and Theme. Hidden branches never receive focus. | Pending |
| Clock and Rhythm | Digital time is readable on demand but not announced each second. State and available Start/Pause/Resume/Stop controls are announced once and match the visual state. | Pending |
| Rhythm Settings | Direct HH:mm fields and the 24-hour picker are keyboard operable. Unsaved and invalid warnings remain distinct; Escape closes a modal without discarding unrelated draft state. | Pending |
| Todo and Calendar | Enter/Space activate controls, calendar arrows move one grid position, edit Escape cancels, and reorder alternatives expose destination and group state. | Pending |
| Data Transfer | Export/import warnings and replacement preview trap focus correctly, expose no Todo titles, and close with Escape/Cancel/Confirm as documented. | Pending |
| Tray and notification | Tray Open/Pause/Resume/Stop/Quit labels and enabled state match the current session. Toast title/body are readable and replacement does not create duplicate active items. | Pending |
| Focus and scaling | Visible focus persists across resize and 200-percent text; no clipped action or unlabeled icon remains at the minimum 720×560 window. | Pending |

## Failure recording

For each failed row, record the tightest reproducible action, expected and observed announcement/focus state, OS/assistive-technology version, artifact hash, and a redacted screenshot or recording reference. Return the defect to the owning P-item. Do not mark the row passed after testing a different hash or a debug build.
