# Provide adaptive and accessible interaction

The Windows window opens at 920×680 logical pixels on first launch and cannot shrink below 720×560. Later launches restore device-local bounds and maximized state, clamping a window back onto an available display when monitor geometry changes. Window state is device-specific and excluded from Portable Backup.

Windows keeps its top segmented navigation and Android keeps its bottom navigation. Content adapts from one column to useful two-column compositions according to available constraints rather than a device-type or orientation check, and Android supports portrait, landscape, split-screen, phones, and tablets without locking orientation. Route content and scroll state survive resizing and ordinary navigation.

The visible Clock page samples wall-clock time once per second, repaints only the clock subtree, stops visual ticking while offstage, and immediately reconciles when shown again. The analog face is decorative semantics; the digital time is readable on demand but is not a live region that interrupts assistive technology every second.

Interactive Android targets are at least 48 logical pixels. Layouts support 200-percent text scaling, TalkBack and Windows Narrator labels, one-time announcements for meaningful state changes, visible focus, and state cues that do not rely on color alone. The eleven canonical theme palettes remain recognizable and unchanged at their source swatches, while derived foreground and focus roles may be minimally adjusted when automated contrast checks would otherwise fail.

Standard Tab and Shift+Tab traversal, Enter and Space activation, Escape dismissal, and arrow-key behavior for segmented controls and calendars are supported. Windows adds `Ctrl+1` through `Ctrl+4` for the four main destinations but no global Start, Pause, Stop for Today, or Delete accelerator.
