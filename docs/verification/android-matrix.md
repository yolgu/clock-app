# Android release matrix

- Qualification: Pending
- APK SHA-256: `311b8dab8e518c55ea93e49cd23da947306b31665e4a228868efda0547d51f8f` (development-signed beta)
- AAB SHA-256: Pending

| Environment | Permissions | Start/delivery | Process removal | Reboot/update | Doze/missed event | Time/timezone | Backup rules | Install/update | TalkBack |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| API 24 emulator | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| API 31 emulator | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| API 33 emulator | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| API 36 emulator | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| Physical device | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |

Each completed cell must name the API level, device/emulator model, build fingerprint, artifact SHA-256, execution date, and redacted evidence reference. Permission grant must never be recorded as an automatic Rhythm start. Force-stop and permission-loss recovery must remain user mediated.

## Observational records

The artifact-bound `InstallSmoke` harness produced API 24 and API 36 records under `artifacts/evidence/android/` on 2026-08-23. Both records deliberately remain `OperatorAssessmentRequired`; they prove installation, launch, package metadata collection, and evidence redaction only, so no matrix cell is marked Passed.

The source-to-emulator debug E2E in `integration_test/app_e2e_test.dart` passed on dedicated API 24, 31, 33, and 36 AVDs. It proves actual Android composition, Drift Todo create/re-read, Calendar navigation, and Flutter Back behavior, but is not an installed release-artifact, permission, lifecycle, update, or physical-device result. Matrix cells therefore remain Pending.
