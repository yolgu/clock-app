# Release evidence index

- Release decision: Beta
- Common automated gate: Passed
- Known blockers: Documented
- Production qualification: Blocked
- Evidence snapshot date: 2026-08-23

Clock Rhythm은 현재 `1.0.0+1` production parity로 판정되지 않습니다. 공통 게이트, beta artifact, API 24/31/33/36 debug E2E, Windows 11 portable lifecycle, 실제 Neutralino → beta → production v1 왕복은 통과했습니다. 물리 Android 기기, Windows 10 및 clean-user 설치 흐름, 서명된 MSIX/AAB, 설치 업데이트와 수동 접근성 증거가 없으므로 release decision은 계속 Beta입니다.

## Automated gates

| Gate | Environment | Result | Evidence |
| --- | --- | --- | --- |
| Generated, format, architecture, analyze, Dart/Flutter tests | Windows 11 25H2, Flutter 3.44.7 | Passed | `tool/verify.ps1 -Platform All`: generated 4 files current, format 325 files unchanged, architecture 226 files, analyze 0 issues, 582 tests passed on 2026-08-23 |
| Android source-to-emulator E2E | API 24, 31, 33, and 36 dedicated AVDs | Passed, debug evidence only | `integration_test/app_e2e_test.dart` exercised actual Android composition, Drift Todo create/re-read, Calendar navigation, and Back; every run used test SHA-256 `ad1f165b38954657d931de76523031622af9d2ea64dbf2e423a5c71aef9bcd06` |
| Windows native lifecycle and beta package | Windows 11 x64 | Passed | `tool/package_windows.ps1 -Flavor Beta -Artifact Zip`; SHA-256 `e5fc939e60b57ff858721d3d4eba303103f3ee2c9eb935f6425857b7ab432c35` |
| Android Kotlin tests and beta APK | Android SDK/API 36 toolchain | Passed | 43 native tests; `tool/package_android.ps1 -Flavor Beta -Artifact Apk`; SHA-256 `311b8dab8e518c55ea93e49cd23da947306b31665e4a228868efda0547d51f8f` |
| Source-to-artifact binding | PowerShell 7 and Windows PowerShell 5.1 | Passed | Source snapshot SHA-256 `4a649d7734e63717ee39f7f536d834d6e9b248a1481b46106cace041ced230ef`; `artifacts/manifest.json` records the same value |
| Portable Backup actual round trip | Windows 11 x64, existing user | Passed | Neutralino v1 → beta → unsigned production portable; envelope, Preferences, and Todo semantics matched; see `backup-roundtrip.md` |
| Accessibility automation | Flutter widget/golden harness | Passed | 48dp, semantics, keyboard/focus, 200% text, 11-theme contrast and representative goldens are included in the 582-test gate |

## Evidence sets

- [Legacy behavior matrix](legacy-behavior-matrix.md)
- [Windows matrix](windows-matrix.md)
- [Android matrix](android-matrix.md)
- [Portable Backup round trip](backup-roundtrip.md)
- [Installed update](installed-update.md)
- [Platform checklist](platform-checklist.md)
- [Manual accessibility checklist](../testing/accessibility-manual-checklist.md)
- Artifact manifest: `artifacts/manifest.json` (generated locally; not release evidence until its files and hashes verify)

The legacy matrix records 160 Verified, 22 ADR-backed Dispositioned, and 0 Pending rows. A Dispositioned row names the Accepted ADR that intentionally replaces a legacy implementation detail and links current regression evidence. The beta ZIP/APK, unsigned production portable ZIP, required notices, hashes, and shared source snapshot were re-read after packaging. Generated artifacts remain ignored by Git and must travel with `SHA256SUMS.txt` outside source control.

## Known blockers

- Windows 10 and Windows 11 clean-user installed behavior has not been recorded against an artifact hash; Windows 11 existing-user portable launch, flavor isolation, and backup are the only completed Windows matrix cells.
- Android API 24/31/33/36 source-to-emulator E2E passed, while artifact-bound permission/lifecycle/update observations and the physical-device matrix remain incomplete.
- Production signing credentials are intentionally absent from the repository; the active user-action report is `blockers/20260823-clock-rhythm-release/production-signing.md`.
- Windows and Android installed-version update rehearsals are incomplete.
- TalkBack and Narrator manual evidence is incomplete.

## Decision rule

`tool/check_release_evidence.ps1 -ReleaseTier Beta` requires a current common gate, a source snapshot that matches the manifest, and verified beta Windows ZIP and Android APK entries. Pending manual cells remain documented limitations. `-ReleaseTier Production` additionally requires every legacy row to be Verified or ADR-backed Dispositioned, every platform/manual matrix, actual backup round trip, installed update, and required production-signed artifacts to be complete.
