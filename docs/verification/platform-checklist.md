# Platform release verification checklist

이 checklist는 자동 test 수가 아니라 실제 behavior, artifact와 platform evidence를 release 자격에 연결합니다. 한 항목이라도 필수 환경에서 실패하거나 실행되지 않았으면 결과를 `Pending` 또는 `Failed`로 남깁니다. Android physical-device 또는 installed-update 증거가 없으면 release decision은 beta이며 `1.0.0+1` production parity를 선언할 수 없습니다.

## Evidence header

각 실행마다 다음 값을 먼저 기록합니다. `<...>` placeholder를 실제 값으로 바꾸되 개인 data와 secret은 기록하지 않습니다.

| Field | Value |
| --- | --- |
| Date/time and time zone | `<ISO-8601 timestamp>` |
| Source revision | `<commit SHA or source snapshot hash>` |
| Artifact path | `<artifact basename>` |
| Artifact SHA-256 | `<sha256>` |
| Flavor/package identity | `<beta-or-production identity>` |
| OS/device/API/architecture | `<environment>` |
| Tester | `<role or redacted identifier>` |
| Result | `Pending / Passed / Failed / Blocked` |
| Evidence reference | `<external evidence ID or repository-relative report>` |

이 header가 다른 artifact hash를 가리키면 이전 결과를 재사용하지 않습니다.

## 1. 공통 자동 gate

저장소 루트에서 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/check_docs.ps1
powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform All
```

- [ ] `.fvmrc`의 Flutter 3.44.7과 committed `pubspec.lock`을 사용했습니다.
- [ ] localization/Drift 생성물 일치, format, architecture, analyze, 전체 Dart/Flutter test가 모두 통과했습니다.
- [ ] Windows native lifecycle harness와 Android Kotlin test가 platform build gate에서 통과했습니다.
- [ ] 실패를 retry로 숨기지 않고 첫 nonzero exit와 원인을 기록했습니다.

자세한 gate 순서는 [CI와 로컬 품질 게이트](ci-gates.md), legacy behavior 연결은 [behavior matrix](legacy-behavior-matrix.md)를 사용합니다.

## 2. Beta artifact smoke

```powershell
powershell -ExecutionPolicy Bypass -File tool/package_windows.ps1 -Flavor Beta -Artifact Zip
powershell -ExecutionPolicy Bypass -File tool/package_android.ps1 -Flavor Beta -Artifact Apk
```

- [ ] Windows beta와 Android beta의 display name, package identity, version이 manifest와 일치합니다.
- [ ] Windows executable은 `clock_rhythm.exe`이고 필요한 Flutter data/runtime/plugin DLL/assets가 함께 있습니다.
- [ ] Android min/target API, ABI와 signature가 artifact 검사 결과와 일치합니다.
- [ ] beta와 production을 동시에 설치했을 때 database, no-backup state, window state, custom media, mutex, notification identity와 autostart registration이 격리됩니다.
- [ ] Unsigned staging output을 releasable 또는 signed artifact로 표시하지 않았습니다.

Production ZIP/MSIX/APK/AAB 조립·검사는 [release 절차](../release/release-process.md)의 credential과 package 계약을 사용합니다.

## 3. Windows 10/11 x64 matrix

Windows 10과 Windows 11 각각에서 동일한 artifact hash로 실행합니다.

| Scenario | Windows 10 x64 | Windows 11 x64 | Required observation |
| --- | --- | --- | --- |
| clean portable launch | Pending | Pending | source/SDK 없이 bundle에서 실행, 920×680 첫 창 |
| min size and restore | Pending | Pending | 720×560 이하 금지, bounds/maximized 복원, off-screen clamp |
| second interactive launch | Pending | Pending | 두 번째 process가 종료되고 기존 창이 show/restore/focus |
| second hidden launch | Pending | Pending | 기존 창을 노출하지 않고 두 번째 process 종료 |
| close and tray Open | Pending | Pending | close는 process를 유지하고 Open은 같은 창 표시 |
| tray commands | Pending | Pending | Pause/Resume/Stop/Quit이 command 하나만 실행 |
| tray Quit | Pending | Pending | schedule/audio 취소, Idle publish, process 종료 |
| unpackaged autostart | Pending | Pending | flavor 전용 quoted executable + `--hidden`, launch는 Idle |
| packaged StartupTask | Pending | Pending | desired/actual/needs-user-action/error 상태가 정확함 |
| notification replacement | Pending | Pending | 현재 Rhythm Event 하나를 stable identity로 교체 |
| bundled/custom/Mute/0% | Pending | Pending | visible notification 유지, sound/volume 계약 일치 |
| custom MP3 ownership | Pending | Pending | ≤20 MiB valid MP3 private copy, 원본 이동 후 재생 |
| Portable Backup | Pending | Pending | export/preview/confirm/full replacement/redaction |
| ZIP install/update | Pending | Pending | 새 사용자 clean launch와 update 후 durable data 유지 |
| MSIX install/update | Pending | Pending | 외부 signing, identity, StartupTask와 durable data 유지 |
| accessibility | Pending | Pending | keyboard, visible focus, Narrator, 200% text, non-color cue; use the [manual accessibility checklist](../testing/accessibility-manual-checklist.md) |

Native 자동화는 다음으로 재확인합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_windows_lifecycle.ps1 -VerifyFlavorIsolation
```

## 4. Android API와 physical-device matrix

API 24, 31, 33, 36 emulator와 적어도 한 physical device에서 [Android emulator E2E](../testing/android-emulator-e2e.md), [Android lifecycle·System Backup checklist](../testing/android-lifecycle-checklist.md)와 [TalkBack/Narrator checklist](../testing/accessibility-manual-checklist.md)를 완료합니다.

| Scenario | API 24 | API 31 | API 33 | API 36 | Physical device |
| --- | --- | --- | --- | --- | --- |
| install/launch and navigation | Pending | Pending | Pending | Pending | Pending |
| notification permission | N/A | N/A | Pending | Pending | Pending |
| exact-alarm access and explicit Start | platform granted | Pending | Pending | Pending | Pending |
| process death/recent-app removal | Pending | Pending | Pending | Pending | Pending |
| force-stop explicit recovery | Pending | Pending | Pending | Pending | Pending |
| reboot and package replacement | Pending | Pending | Pending | Pending | Pending |
| wall-clock/time-zone change | Pending | Pending | Pending | Pending | Pending |
| permission revoke/grant | Pending | Pending | Pending | Pending | Pending |
| Doze and missed-boundary skip | Pending | Pending | Pending | Pending | Pending |
| encrypted cloud/device transfer | transport dependent | transport dependent | transport dependent | transport dependent | Pending |
| portrait/landscape/split-screen | Pending | Pending | Pending | Pending | Pending |
| TalkBack/200% text/48dp target | Pending | Pending | Pending | Pending | Pending |
| APK install/update data retention | Pending | Pending | Pending | Pending | Pending |
| AAB inspection/install path | Pending | Pending | Pending | Pending | Pending |

Focus 또는 Rest Interval이 9분보다 짧은 경우 deep idle 지연 가능성을 별도로 기록합니다. Exact delivery가 늦으면 과거 boundary를 replay하지 않고 strictly future boundary로 이동해야 합니다. Foreground service, permanent notification, full-screen intent 또는 battery-optimization exemption을 임시 해결책으로 추가하지 않습니다.

## 5. 실제 backup과 cutover rehearsal

[Neutralino → Flutter 마이그레이션](../migration/neutralino-to-flutter.md)을 실제 사용자 흐름으로 수행합니다.

- [x] 실제 Neutralino schema-version-1 export를 보존하고 SHA-256을 기록했습니다.
- [x] Flutter beta preview에서 title 없이 counts/date range/rhythm/language/theme/autostart/custom sanitization을 확인했습니다.
- [x] beta import 후 Preferences와 Todo 의미 동등성을 확인했습니다.
- [x] beta에서 다시 v1을 export했습니다.
- [x] accepted beta v1을 production에 import하고 의미 동등성을 확인했습니다.
- [x] source backup이 bundled default sound를 사용해 Custom Notification Sound 재선택 대상이 없음을 확인했습니다.
- [x] 이전 앱을 종료했고 자동 시작이 꺼진 상태에서 새 설치의 데이터 흐름만 검증했으며 Rhythm Start는 실행하지 않았습니다.
- [ ] pre-cutover JSON과 이전 private store를 유지한 rollback rehearsal을 완료했습니다.
- [x] direct database copy, downgrade, reverse migration 또는 자동 uninstall을 사용하지 않았습니다.

## 6. Privacy와 artifact inspection

- [ ] Android release manifest에 `INTERNET`, account, analytics, crash-reporting surface가 없습니다.
- [ ] Release traffic 관찰에서 app-originated network connection이 없습니다.
- [ ] Portable Backup에는 Preferences/Todo만 있고 custom binary/path, draft, session, permission, alarm ID가 없습니다.
- [ ] Android System Backup에는 flavor별 SQLite database와 `-journal`만 있고 shared preferences/no-backup/cache/path가 없습니다.
- [ ] Restore 후 Rhythm Session이 Idle이고 native alarm이 복원되지 않습니다.
- [ ] Log/evidence에 Todo title, 전체 selected-file path 또는 signing secret이 없습니다.
- [ ] [Product Asset Notice](../../ASSET_NOTICE.md)와 [Third-Party Theme Notices](../../THIRD_PARTY_NOTICES.md)가 artifact와 함께 제공됩니다.

## 7. Release decision

| Decision | Minimum condition |
| --- | --- |
| Development build | Focused tests와 해당 platform debug smoke를 통과했지만 배포 artifact가 아님 |
| Beta candidate | 공통 gate와 beta artifact inspection이 통과하고 알려진 platform/evidence gap이 문서화됨 |
| Beta | P20 beta artifact 계약과 허용된 beta 검증 범위를 통과함; production parity를 주장하지 않음 |
| Production `1.0.0+1` | 모든 legacy/new behavior, Windows 10/11, Android API/physical, 실제 v1 roundtrip, installed update, privacy, accessibility, signed artifact evidence가 동일 hash에 연결됨 |

Production credential이 없거나, physical Android·Windows matrix·installed update 중 하나라도 누락되면 최종 decision은 beta입니다. Store enrollment와 submission은 production qualification 이후에도 별도 release-owner 작업입니다.
