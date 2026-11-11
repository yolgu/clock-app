# Replace inherited theme palettes with original palettes

> Light variants and the separate Appearance preference are added by [ADR 0026](0026-store-appearance-apart-from-the-palette.md). The lightness ladder below describes the dark variant.

All eleven themes now use original Clock Rhythm palettes and names: Graphite, Midnight, Slate, Dusk, Glacier, Orchid, Ember, Aurora, Moss, Sunset and Mono. Names taken from editor themes could read as product affiliation, and the inherited palettes did not share a lightness scale, so contrast and visual weight differed from theme to theme.

Every palette is defined in OKLCH on one shared lightness ladder (background 0.15, surface 0.195, text 0.935, primary accent 0.735, secondary accent 0.805, danger 0.705); themes differ only in hue and chroma. Under the derivation rules in `ClockRhythmTheme`, every theme keeps body text, accent-as-text and danger text at or above 4.5:1 without falling back to substitute colors. The danger role keeps the same red family in every theme so its meaning never shifts.

The schema-version-1 identifiers stay unchanged as stored values. A backup that names `tokyo-night` still loads and selects the theme in that position, now Midnight. This supersedes the palette-preservation parts of ADR 0014 and ADR 0019; their compatibility guarantees for stored identifiers remain in force.
