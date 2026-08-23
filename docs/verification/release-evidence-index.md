# Release evidence index

- Release decision: Beta
- Common automated gate: Passed
- Known blockers: Documented
- Production qualification: Blocked
- Evidence snapshot date: 2026-08-23

Clock Rhythm은 현재 `1.0.0+1` production parity로 판정되지 않습니다. 자동 게이트와 beta artifact 검사는 이 문서에 실제 명령, 산출물 SHA-256, 실행 환경을 연결한 뒤에만 통과로 바꿉니다. 물리 Android 기기, Windows 10/11 설치 흐름, 서명된 MSIX/AAB, 설치 업데이트, 실제 Neutralino cutover 증거가 없으면 production 판정은 계속 차단됩니다.

## Automated gates

| Gate | Environment | Result | Evidence |
| --- | --- | --- | --- |
| Generated, format, architecture, analyze, Dart/Flutter tests | Windows 11 25H2, Flutter 3.44.7 | Passed | `tool/verify.ps1 -Platform All`: generated 4 files current, format 325 files unchanged, architecture 226 files, analyze 0 issues, 579 tests passed on 2026-08-23 |
| Android source-to-emulator E2E | API 24 and API 36 dedicated AVDs | Passed, debug evidence only | `integration_test/app_e2e_test.dart` exercised actual Android composition, Drift Todo create/re-read, Calendar navigation and Back; final API 36 run is bound to source snapshot `1cea44f26ce5cfb68e51ae2b18d2b9ae555f09fc78d84a0b64e72adde5487f42` |
| Windows native lifecycle and beta package | Windows 11 x64 | Passed | `tool/package_windows.ps1 -Flavor Beta -Artifact Zip`; SHA-256 `b5ebdbc4d2a8d7cabe748a86ccabc4621a13b6ac66cfa5dbdf0612403f789bec` |
| Android Kotlin tests and beta APK | Android SDK/API 36 toolchain | Passed | 43 native tests; `tool/package_android.ps1 -Flavor Beta -Artifact Apk`; SHA-256 `311b8dab8e518c55ea93e49cd23da947306b31665e4a228868efda0547d51f8f` |
| Source-to-artifact binding | PowerShell 7 and Windows PowerShell 5.1 | Passed | Both runtimes computed source snapshot SHA-256 `1cea44f26ce5cfb68e51ae2b18d2b9ae555f09fc78d84a0b64e72adde5487f42`; `artifacts/manifest.json` records the same value |
| Accessibility automation | Flutter widget/golden harness | Passed | 48dp, semantics, keyboard/focus, 200% text, 11-theme contrast and representative goldens are included in the 579-test gate |

## Evidence sets

- [Legacy behavior matrix](legacy-behavior-matrix.md)
- [Windows matrix](windows-matrix.md)
- [Android matrix](android-matrix.md)
- [Portable Backup round trip](backup-roundtrip.md)
- [Installed update](installed-update.md)
- [Platform checklist](platform-checklist.md)
- [Manual accessibility checklist](../testing/accessibility-manual-checklist.md)
- Artifact manifest: `artifacts/manifest.json` (generated locally; not release evidence until its files and hashes verify)

The legacy matrix records 160 Verified, 22 ADR-backed Dispositioned, and 0 Pending rows. A Dispositioned row names the Accepted ADR that intentionally replaces a legacy implementation detail and links current regression evidence. The two beta artifact files, their hashes, and their shared source snapshot were re-read after packaging. Generated artifacts remain ignored by Git and must travel with `SHA256SUMS.txt` outside source control.

## Known blockers

- Windows 10 and Windows 11 installed behavior has not been recorded against an artifact hash.
- Android API 24/36 source-to-emulator E2E passed, while their artifact-bound lifecycle observations still await operator assessment; API 31/33 and the full emulator/physical-device lifecycle matrices remain incomplete.
- Production signing credentials are intentionally absent from the repository.
- Actual Neutralino → beta → production migration and installed-version update rehearsals are incomplete.
- TalkBack and Narrator manual evidence is incomplete.

## Decision rule

`tool/check_release_evidence.ps1 -ReleaseTier Beta` requires a current common gate, a source snapshot that matches the manifest, and verified beta Windows ZIP and Android APK entries. Pending manual cells remain documented limitations. `-ReleaseTier Production` additionally requires every legacy row to be Verified or ADR-backed Dispositioned, every platform/manual matrix, actual backup round trip, installed update, and required production-signed artifacts to be complete.
