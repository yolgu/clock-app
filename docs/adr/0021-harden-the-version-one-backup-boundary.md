# Harden the version-one backup boundary

One installation holds at most 25,000 Todos, enforced when adding a Todo so every valid local state remains exportable. Portable Backup import reads at most 32 MiB and rejects either limit before stopping a Rhythm Session or mutating durable data.

A version-one envelope requires exact app name `Clock Rhythm`, integer schema version `1`, a valid exported timestamp, Preferences, and a Todo array. Unknown additive fields such as the retired `googleTaskId` are accepted and discarded on the next export, but an unknown schema version is never guessed or downgraded.

Missing optional legacy Preferences restore to Korean, `current`, bundled default sound, and incomplete initial setup. A present invalid value rejects the whole backup rather than being coerced, except that a valid Custom Notification Sound preference is deliberately sanitized to bundled default sound because media is not portable.

Every Todo requires a unique, nonempty identifier no longer than 128 characters, a valid Todo Title and Local Calendar Date, an optional valid 24-hour Todo Time, a Boolean completion value, parseable creation and update instants with update no earlier than creation, and a nonnegative integer display order when present. One invalid Todo rejects the entire import with an indexed, localized error that does not log the title. A missing legacy display order derives from creation time; valid order values remain unchanged and ties sort deterministically by creation time and identifier.

The confirmation preview reports total and completed counts, the Todo date range, rhythm configuration, language, theme, automatic-start impact, export time, and Custom Notification Sound sanitization without displaying Todo titles.
