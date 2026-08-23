# Android lifecycle and System Backup checklist

Use a beta or debug application ID and disposable test data. Record the device
model, Android version, API level, build SHA, package ID, and wall-clock time for
every run. Do not use a production user profile for time-zone, permission,
force-stop, or restore checks.

## Automated prerequisites

Run these checks before device testing:

```powershell
fvm flutter test test/contexts/rhythm/infrastructure/android --reporter expanded
Push-Location android
.\gradlew.bat testRhythmDebugUnitTest :app:compileDebugKotlin :app:compileReleaseKotlin :app:processReleaseMainManifest
Pop-Location
fvm dart run tool/check_architecture.dart
fvm flutter analyze
```

The checked-in backup policy is a flavor-specific allowlist. Production allows
only `clock_rhythm.sqlite` and its rollback-mode
`clock_rhythm.sqlite-journal`; beta allows only `clock_rhythm_beta.sqlite` and
`clock_rhythm_beta.sqlite-journal`. WAL and SHM files are deliberately omitted
because the current database connection does not enable WAL mode. Shared
preferences, no-backup delivery state, alarm IDs, revisions, permission state,
diagnostics, drafts, window state, and device paths must never appear in a
backup payload.

On Android 11 and lower, each database file has separate
`clientSideEncryption` and `deviceToDeviceTransfer` includes so either secure
transport is eligible. Android 8.1 and lower do not support these transport
conditions and therefore do not back up the allowlisted files. On Android 12 and
higher, cloud backup is disabled without encryption capabilities, while the same
database allowlist is independently enabled for device transfer.

## API matrix

Exercise API 24, 31, 33, and 36. Perform the notification permission scenarios
on API 33 and 36, and the exact-alarm scenarios on API 31, 33, and 36. API 24
must report exact-alarm access as granted by platform policy.

For each row, create an active Rhythm Session with at least three future native
occurrences and record the current revision and next timestamp from app
diagnostics before applying the action.

| Scenario | Action | Required result |
| --- | --- | --- |
| Flutter process death | `adb shell am kill <package-id>`, then launch normally | The pending alarm remains registered. Foreground audit restores Running only when the stored revision has a current native registration. |
| Recent-app removal | Swipe the app from Recents, wait, then reopen | Delivery continues without a service. Reopen shows Running and does not duplicate the alarm or notification. |
| Reboot | Reboot after starting a session | `BOOT_COMPLETED` replaces the old-boot registration with a higher revision and future local timestamps. |
| Package replacement | Install a newer build over the active test build | `MY_PACKAGE_REPLACED` replaces the stale revision without starting an inactive session. |
| Manual wall-clock change | Move the clock across at least one planned boundary in Settings | `TIME_SET` skips missed boundaries, creates a higher revision, and registers only a future occurrence. |
| Time-zone change | Change to a zone with a different UTC offset in Settings | `TIMEZONE_CHANGED` recomputes local Daily Rhythm timestamps and removes the old registration. |
| Exact-alarm revoke | Revoke Alarms & reminders while active, then reopen | Android cancels the exact alarm. Foreground audit remains non-Running and requires an explicit recovery action. |
| Exact-alarm grant | Grant Alarms & reminders after the previous row | The grant broadcast does not schedule or start delivery. Recovery remains user-mediated. |
| Notification revoke | Disable notifications while active, then foreground the app | Foreground audit cancels delivery and reports permission recovery; Todo and other non-Rhythm features remain usable. |
| Force-stop | Force-stop the active package and launch it explicitly | Missing PendingIntent evidence prevents silent Running restoration. The UI offers explicit Recovery/Start. |
| Doze | Enter Doze with an active future event | A late event is not replayed after a newer boundary; foreground/lifecycle reconciliation arms a future occurrence. |

Useful read-only inspection commands:

```powershell
adb shell dumpsys alarm | Select-String '<package-id>'
adb shell dumpsys package <package-id> | Select-String 'SCHEDULE_EXACT_ALARM|POST_NOTIFICATIONS'
adb shell dumpsys notification --noredact | Select-String 'clock-rhythm-event|<package-id>'
```

The artifact-bound harness records a redacted device identifier hash, API/model/fingerprint, artifact hash, package capability summary, and alarm/notification reference counts. `Inspect` is read-only. Other scenarios make only the named package action shown by the scenario and always leave the result for operator assessment:

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_android_lifecycle.ps1 `
  -DeviceId <adb-device-id> `
  -ApkPath artifacts/android/clock-rhythm-beta-0.1.0+1.apk `
  -Flavor Beta `
  -Scenario Inspect
```

`InstallSmoke`, `ProcessDeath`, `ForceStopRecovery`, and `PackageReplacement` must be run only on the disposable profile named in the evidence header. The generated JSON is observational evidence, not a pass, until the operator completes its assessment and links the redacted recording or screenshot.

## System Backup and restore

Test both an encrypted cloud-capable transport and the setup-wizard
device-to-device path when the lab provides them. `bmgr` availability alone does
not prove client-side encryption or device-to-device behavior; record the active
transport and its reported flags.

1. Create recognizable Preferences and Todos, then stop all writes and request a
   backup using the lab transport.
2. Inspect the transport payload or transport logs. Production may list only
   `files/clock_rhythm.sqlite` and `files/clock_rhythm.sqlite-journal`; beta may
   list only `files/clock_rhythm_beta.sqlite` and
   `files/clock_rhythm_beta.sqlite-journal`.
3. Confirm that both flavor DB names' `-wal` and `-shm` files,
   `shared_prefs/`,
   `no_backup/rhythm-delivery-state.bin`, caches, diagnostics, drafts, custom
   media paths, and all other files are absent.
4. Restore onto a clean installation. Preferences and Todos must return, while
   Rhythm is Idle and no alarm, recovery marker, permission result, draft, or
   device path is restored.
5. Repeat cloud backup without encryption capabilities. No Clock Rhythm data may
   be uploaded. Repeat with an eligible encrypted transport and confirm the same
   flavor's two-file allowlist.

Representative lab commands, when supported by the selected transport:

```powershell
adb shell bmgr enabled
adb shell bmgr list transports
adb shell bmgr backupnow <package-id>
adb shell dumpsys backup
```

## Evidence record

For every scenario retain:

- device/API/build/package identity;
- before and after revision, next local timestamp, capability status, and
  recovery disposition;
- relevant `dumpsys alarm`, notification, and backup-transport excerpts;
- screen recording for permission, force-stop, reboot, and restore flows;
- pass/fail result and defect link.

A missing API level, physical-device permission flow, reboot/Doze run, or real
backup transport remains an explicit release-evidence gap and keeps the Android
build in beta.
