# Installed update evidence

- Qualification: Pending
- Windows installed update: Pending
- Android installed update: Pending
- Side-by-side beta/production isolation: Pending

## Windows

Verify an existing beta and production installation independently. Record that update preserves the correct DB, device-local draft/window state, notification sound selection, mutex, toast identity, and autostart registration without reading or changing the other flavor or Neutralino data.

## Android

Verify APK/AAB update behavior for both application IDs. Record that the durable Preferences/Todos DB survives, no-backup Rhythm delivery state is not restored from Android System Backup, notification channels remain flavor isolated, and a stale or interrupted session follows the foreground recovery decision table.

## Evidence contract

Every run must include before/after version, package identity, artifact SHA-256, OS/API version, date, and a redacted result reference. A debug reinstall, clean install, copied DB, or synthetic fixture is not installed-update evidence.
