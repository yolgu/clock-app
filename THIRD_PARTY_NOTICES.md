# Third-Party Theme Notices

Clock Rhythm redistributes no third-party theme names or palette swatches. All eleven themes are original Clock Rhythm palettes designed for this product (see [ADR 0024](docs/adr/0024-replace-inherited-theme-palettes-with-original-palettes.md)).

The stable backup IDs such as `tokyo-night`, `nord` and `dracula-official` remain only as schema-version-1 storage values so existing Portable Backups keep loading. They are never displayed and no longer select the projects those identifiers were named after.

| Stored ID | Displayed theme |
| --- | --- |
| `current` | Graphite |
| `tokyo-night` | Midnight |
| `one-dark-pro` | Slate |
| `catppuccin-mocha` | Dusk |
| `nord` | Glacier |
| `dracula-official` | Orchid |
| `gruvbox` | Ember |
| `monokai-pro` | Aurora |
| `night-owl` | Moss |
| `synthwave-84` | Sunset |
| `ayu-mirage-dark` | Mono |

Releases built before ADR 0024 derived nine palettes from MIT-licensed projects; their notices ship inside those earlier artifacts.
