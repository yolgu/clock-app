# Store Appearance apart from the palette

Every palette now has a dark and a light variant, and the user picks the Appearance (System, Light or Dark) separately from the palette on the Theme page. Dark stays the standard Appearance. A light-mode copy of each palette would have doubled the stored theme identifiers and broken the meaning of schema-version-1 `theme` values, so the palette identifier keeps naming the palette alone and Appearance is a second Preference.

Both variants come from the Clock Rhythm design system: six seed colors per palette and mode (background, surface, text, primary accent, secondary accent, danger) and one derivation recipe per mode in `ClockRhythmTheme`. Light derives its surfaces, dividers, muted text and soft containers with its own mix ratios and puts white text on accent and danger fills where dark uses black. The outline role still keeps at least 3:1 against the surface in both modes, which is stricter than the design system's raw mix ratio.

The local database moves from schema version 1 to 2 by adding a non-null `appearance` column defaulting to `dark`, so an existing installation opens dark exactly as before. A database whose version is newer than the app still enters recovery instead of being opened.

Portable Backup stays schema version 1. Export writes `appearance` next to `theme`; import treats a missing `appearance` as dark and rejects a present unknown value, following ADR 0021. Neutralino backups therefore restore their palette in dark. The Neutralino importer has not been re-run against a backup that contains `appearance`; the cutover in ADR 0017 only moves data from Neutralino to Flutter.
