# Privacy와 data 범위

Clock Rhythm은 local-first 애플리케이션입니다. 첫 release에는 계정, 애플리케이션 관리 cloud sync, analytics, 광고, remote crash reporting 또는 그 밖의 app-originated network traffic이 없습니다. 데이터는 운영체제의 private application storage에 저장되지만 application-level encryption을 추가로 적용하지 않습니다.

## Release network 계약

Android release manifest인 [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)은 `INTERNET` permission을 선언하지 않습니다. Flutter hot reload와 debugger 연결을 위해 debug/profile manifest에는 개발 전용 `INTERNET` permission이 있지만, 이를 release 기능이나 원격 전송 증거로 해석하면 안 됩니다.

Windows release에도 network 기능이나 account adapter가 없습니다. Production 판정 전에는 [플랫폼 checklist](verification/platform-checklist.md)에서 release artifact의 manifest와 실제 traffic을 다시 검사합니다.

## 저장되는 데이터

| 데이터 | 위치와 수명 | Portable Backup | Android System Backup |
| --- | --- | --- | --- |
| Preferences와 Todo | flavor별 private SQLite database | 포함 | 조건부 포함 |
| Rhythm Session과 native alarm revision | memory 또는 Android no-backup storage | 제외 | 제외 |
| 예약 notification ID와 permission 상태 | device/platform state | 제외 | 제외 |
| Rhythm Settings Draft | replaceable device-local preferences | 제외 | 제외 |
| Windows Custom Notification Sound | flavor별 private media directory | 제외 | 해당 없음 |
| custom media의 private/source path | device-local locator | 제외 | 제외 |
| Windows window bounds/maximized | flavor별 Local AppData | 제외 | 해당 없음 |
| 진단·cache·temporary file | device-local | 제외 | 제외 |

Preferences에는 Focus/Rest 간격, Daily Rhythm, 언어, theme, sound mode/volume, Windows 자동 시작의 desired value와 초기 설정 상태가 포함됩니다. Todo에는 title, Local Calendar Date, 선택적 표시 시간, 완료 상태, display order와 생성·수정 시각이 포함됩니다.

## Portable Backup

Portable Backup은 Data 화면에서 사용자가 직접 export/import하는 다음 계약의 파일입니다.

- exact `appName: "Clock Rhythm"`과 integer `schemaVersion: 1`을 가진 UTF-8 JSON
- Preferences와 최대 25,000개의 Todo
- 최대 파일 크기 32 MiB
- 암호나 application-level encryption 없음
- import 전 전체 validation과 title 없는 summary preview
- 사용자 확인 후 현재 Preferences/Todo를 한 transaction에서 완전히 교체

Custom Notification Sound가 선택된 상태를 export하면 bundled default sound로 sanitize되며 binary, 원본 path, private path를 기록하지 않습니다. Rhythm Session과 예약 정보도 포함하지 않으므로 import는 delivery를 자동으로 시작하지 않습니다.

파일에는 Todo title과 일상 정보가 평문으로 들어갈 수 있습니다. 공유 cloud folder, issue tracker, chat 또는 release evidence에 올리지 말고 사용자가 통제하는 위치에 보관합니다. 파일을 폐기할 때는 사용하는 storage와 backup 서비스의 삭제·휴지통 정책도 확인합니다.

## Android System Backup

Android System Backup은 Portable Backup과 별개이며 사용자가 JSON을 선택하는 기능이 아닙니다. flavor별 XML allowlist는 해당 private SQLite database와 rollback journal만 포함합니다.

- Android 11 이하에서는 client-side encryption이 가능한 cloud transport 또는 device-to-device transfer만 허용합니다. 이 transport flag를 지원하지 않는 Android 8.1 이하에서는 allowlisted data도 cloud backup 대상이 아닙니다.
- Android 12 이상 cloud backup은 encryption capability가 없으면 비활성화됩니다. Device-to-device transfer는 별도 allowlist를 사용합니다.
- SQLite `-wal`/`-shm`, shared preferences, Android no-backup delivery state, permission, alarm ID/revision, diagnostics, draft, cache와 device path는 제외합니다.
- restore 후 Preferences와 Todo는 돌아올 수 있지만 Rhythm Session은 Idle이며 alarm을 자동 복원하면 안 됩니다.

운영체제 transport 구현과 사용자 Google/제조사 설정에 따라 실제 backup 가능 여부가 달라집니다. `bmgr` 명령이 있다는 사실만으로 encryption이나 device-to-device 조건이 충족됐다고 간주하지 않습니다. 실제 payload와 transport flag 검증은 [Android lifecycle·System Backup checklist](testing/android-lifecycle-checklist.md)에 기록합니다.

## 오류, recovery와 삭제

Database migration 또는 integrity 검사에 실패하면 앱은 빈 database로 조용히 초기화하지 않습니다. 원본 database를 보존하고 recovery 화면에서 Retry, Portable Backup Import 또는 확인된 Reset을 제공합니다. Reset은 기존 database와 journal/WAL/SHM을 timestamped recovery directory로 옮긴 후에만 새 database를 만듭니다.

Clock Rhythm에는 account 삭제나 remote data 삭제 기능이 없습니다. 앱 제거·private storage 삭제·Portable Backup 삭제는 각 운영체제와 사용자가 소유합니다. Neutralino/beta/production 전환 중에는 [마이그레이션 가이드](migration/neutralino-to-flutter.md)의 rollback이 끝날 때까지 이전 store와 pre-cutover JSON을 보존합니다.

## 진단 자료 취급

Release evidence와 troubleshooting 기록에는 다음을 넣지 않습니다.

- Todo title 또는 backup 원문
- user-selected file의 전체 path
- certificate, keystore, password, token 또는 signing environment 값
- Android notification의 개인 content를 포함한 무편집 dump

필요한 경우 filename은 basename 또는 `<selected-mp3>`로, path는 `<private-app-data>`로, 개인 문자열은 redacted placeholder로 바꿉니다. Artifact hash, package identity, OS/API 버전, event revision과 timestamp는 개인 내용 없이 남길 수 있습니다.
