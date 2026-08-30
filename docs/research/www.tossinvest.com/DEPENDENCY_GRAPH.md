# Source dependency decision

No DOM, CSS, JavaScript, canvas, chart, media, or third-party source dependency will be ported.

The source page is a design-token reference rather than an implementation clone. Clock Rhythm keeps
its existing Flutter, Material, Riverpod, and GoRouter stack and adds no package. The translated
dependency path is:

`ThemeCatalog source swatches -> ClockRhythmTheme semantic roles -> shared design tokens and card -> platform shell and feature presentation widgets`

