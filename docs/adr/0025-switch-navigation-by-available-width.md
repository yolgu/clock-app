# Switch navigation by available width

The main navigation follows the room the window has, not the platform. At 920 logical pixels and wider, with body text scaled to 150 percent or less, a 232-pixel sidebar lists the five destinations beside the page. Narrower windows and larger text use a bottom tab bar on every platform, so a narrow Windows or macOS window looks like the phone layout and an Android tablet in landscape gets the sidebar.

The sidebar shows the `Ctrl+1` to `Ctrl+5` shortcuts as `Ctrl+N` on Windows and `⌃N` on macOS and hides them on Android, where a hardware keyboard is not expected. Up and Down move between sidebar destinations without wrapping, as Left and Right did in the former top segmented control. Pages receive the width beside the sidebar as their viewport, so their one- and two-column decisions keep working from available constraints.

This supersedes the platform-fixed navigation in ADR 0014 (Windows top segmented navigation, Android bottom navigation). Its other adaptive, keyboard and accessibility guarantees, including 48-pixel targets and 200-percent text support, remain in force; ADR 0014's `Ctrl+1` through `Ctrl+4` now extend to `Ctrl+5` for Settings.
