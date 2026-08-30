# Source behavior observations

- The top navigation and bottom ticker remain fixed.
- Main tabs expose selected semantics and an underline-style selection state.
- Filters use radio and segmented-control semantics.
- Buttons and interactive rows use 200-millisecond hover and pressed transitions.
- The page provides a dark/light screen-mode toggle; semantic hierarchy remains consistent across
  both modes.
- The focused product opens a persistent detail panel and additional interest rail.
- Narrow viewports do not reflow the desktop workspace and instead expose horizontal overflow.

Clock Rhythm will reuse only the visual state hierarchy and motion character. Existing native
Windows and Android navigation, focus, touch, resize, and back behavior remain authoritative.

