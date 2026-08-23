# Clock Rhythm Neutralino → Flutter 포팅 실행 계획

## 1. Executive Summary

이 계획은 `C:\Users\wndls\projects\clock-app`의 Neutralinojs + React + TypeScript 제품을 `C:\Users\wndls\projects\clock-app-flutter`의 독립 Flutter 저장소로 옮기는 실행 계약입니다. 목표는 UI를 픽셀 단위로 복제하는 것이 아니라 Rhythm, Todo/Calendar, Preferences, tray/background delivery, Portable Backup의 행동과 데이터 호환성을 Windows 10/11 x64 및 Android API 24+에서 재현하는 것입니다. 순수 Dart 도메인을 먼저 고정하고 Drift, Riverpod, `go_router`, 최소 native adapter를 단계적으로 붙인 뒤 실제 Neutralino v1 backup 왕복, 설치 update, Windows matrix, Android 실기기 lifecycle/Doze 증거로 `1.0.0+1` 자격을 판정합니다. 가장 큰 위험은 현재 워크스테이션 도구체인 부재, Android background exact-alarm 수명주기, Windows 단일 인스턴스/autostart packaging 차이, legacy backup의 destructive replacement, theme/asset 재배포 권리입니다. 각 위험은 독립 P-item, failure-first test, isolated beta identity, 명시적 rollback과 evidence gate로 통제합니다.

## 2. Extracted Context

- User goal: 기존 Clock Rhythm 전체 제품을 Flutter로 포팅해 Windows와 모바일(Android)에서 사용하고, 합의된 문서와 ADR을 바로 실행할 수 있는 단계별 계획으로 만듭니다.
- Current situation:
  - 대상 저장소에는 `CONTEXT.md`와 22개 ADR만 있고 Flutter project와 Git 저장소는 아직 없습니다.
  - 원본은 `C:\Users\wndls\projects\clock-app`의 `dev` branch이며 remote는 `https://github.com/wndlsrnr1/clock-app.git`입니다. 원본은 읽기 전용 참조로 유지합니다.
  - 원본에는 49개 테스트 파일과 182개 executable test case가 있으며 Rhythm, Preferences, Todo, Data Transfer, architecture/UI behavior를 보호합니다. 초기 183개 집계는 `RegExp.test()` 한 줄을 테스트 선언으로 센 정규식 오탐이었습니다.
  - 원본 자산은 `public/icon.png`와 `src/assets/CHIME14.mp3`이고 repository 안에 provenance/license 기록이 없습니다.
  - 대상 워크스테이션 PATH에서 Flutter, FVM, Java, adb, CMake가 확인되지 않았고 일반적인 Visual Studio/Android SDK 경로도 확인되지 않았습니다.
- Stakeholders / users:
  - Windows 10/11 x64와 Android phone/tablet에서 개인 생산성 workflow를 사용하는 최종 사용자.
  - beta/production artifact를 만들고 signing material과 실제 device를 관리하는 release owner.
  - 이 plan bundle을 따라 P-item을 하나씩 실행하고 evidence ledger를 갱신하는 개발자 또는 에이전트.
- Constraints:
  - 자연어·route·backup의 제품명은 `Clock Rhythm`; Dart project/package는 `clock_rhythm`; Windows executable은 `clock_rhythm.exe`입니다.
  - Flutter 3.44.7을 FVM으로 pin하고 `pubspec.lock`을 보존합니다.
  - Android production ID는 `dev.wndls.clockrhythm`, beta는 `dev.wndls.clockrhythm.beta`; min API 24, compile/target API 36입니다.
  - Windows beta/production도 package identity, storage, mutex, notification, autostart가 서로 달라야 합니다.
  - 시스템 도구 설치, Android license 수락, production signing credential 제공은 사용자/운영자 작업이며 plan 실행이 자동 수행하지 않습니다.
  - GitHub Actions 파일은 만들지만 remote 생성, push, store enrollment/submission은 하지 않습니다.
- Existing assets:
  - `CONTEXT.md`의 공통 언어와 22개 accepted ADR.
  - Neutralino source, 실제 v1 backup behavior, 11 theme IDs, icon, bundled MP3, 182개 executable test behavior.
  - 기존 기본값: Focus 50분, Rest 10분, Daily Rhythm 05:00–18:00, Korean, `current`, default sound, autostart off, initial setup false.
- Technology choices:
  - Flutter/Dart, Riverpod Notifier/AsyncNotifier, `go_router`의 `StatefulShellRoute.indexedStack`, Drift + SQLite, Flutter `gen_l10n` ARB.
  - core version line: `flutter_riverpod` 3.4.x, `go_router` 17.5.x, `drift` 2.34.x, `drift_flutter` 0.3.x.
  - platform packages behind owned ports: `window_manager`, `tray_manager`, `flutter_local_notifications`, `file_picker`, `audioplayers`, `path_provider`; `shared_preferences`는 replaceable noncritical UI state만 소유; `msix`는 packaging tooling입니다.
  - Drift와 `gen_l10n` 외 codegen을 추가하지 않습니다. Riverpod Generator, Freezed, `go_router_builder`, GetIt, unpinned Git/fork dependency를 사용하지 않습니다.
- Assumptions:
  - 사용자와 합의한 제품·도메인 결정에는 blocking ambiguity가 없습니다.
  - P0 실행 시 위 version line 안의 안정 patch 버전을 선택하고 생성된 `pubspec.lock`을 dependency SSOT로 사용합니다.
  - Android exact-alarm bridge의 background Flutter callback이 API 24/31/33/36 및 physical device에서 검증되지 않으면 foreground service로 조용히 범위를 바꾸지 않고 beta blocker로 남깁니다.
  - source test 수는 TypeScript AST 기준 49/182이며 P1에서 source commit SHA와 test title inventory를 고정합니다.
- Open questions:
  - 제품/아키텍처 blocking question은 없습니다.
  - production certificate/keystore, Windows 10/11 검증 장치, Android physical device는 release 전 외부 입력이 필요합니다. 제공되지 않으면 beta까지는 진행할 수 있으나 P22 production 판정은 실패합니다.
- Context used:
  - `CONTEXT.md`, `docs/adr/0001`–`0023`, 원본 source/domain/application/presentation/packaging 파일, 원본 49/182 테스트 inventory, 사용자와 확정한 platform/product decisions.

## 3. Success Criteria

| Goal | Measure | Verification |
| ---- | ------- | ------------ |
| 전체 제품 범위 | Clock/Rhythm, Todo/Calendar, Preferences, Theme, Data, Windows tray/background가 모두 사용 가능 | P10–P18 widget/integration evidence와 P22 behavior matrix |
| Rhythm 정확성 | Daily Rhythm anchor, cross-midnight, pause/resume, missed skip, Stop rollover, settings reschedule 결정표 전부 통과 | P2 fake-clock suite, P16/P17 platform matrix |
| Todo 정확성 | Local Calendar Date, 1–160 grapheme, optional display time, group ordering/reorder, 25,000 limit | P4 domain suite, P11 widget suite, P6 import limits |
| v1 데이터 호환 | 실제 Neutralino export를 import/export하고 Preferences/Todos 의미가 동일 | P6 fixture round trip, P22 actual roundtrip evidence |
| 원자성·복구 | import/migration fault가 기존 DB를 보존하고 silent reset이 없음 | P5 real-DB failure injection, P13 recovery flow |
| Windows 지원 | Windows 10/11 x64에서 창/tray/single instance/autostart/MP3/notification/install/update 통과 | P14/P15 harness, P20 artifact inspection, P22 matrix |
| Android 지원 | API 24/31/33/36 emulator와 physical device에서 permissions/alarm/process/reboot/Doze/time 변화 통과 | P16/P17 native tests와 P22 matrix |
| 접근성·적응성 | 48dp, 200% text, keyboard, TalkBack/Narrator, contrast/focus/non-color cues 통과 | P18 automated/golden/manual evidence |
| 배포 격리 | beta/production이 storage, identity, autostart, notification을 공유하지 않음 | P20 side-by-side install tests |
| 프라이버시 | 계정/analytics/network 없음, title/full path 로그 없음, backup 범위 최소화 | P5/P6/P17 tests, P22 traffic/log/artifact inspection |
| 재현 가능한 품질 | FVM/lockfile, generation, format, analyze, architecture, tests, release builds가 공통 gate로 green | P19 local/CI scripts와 P22 evidence |
| 안전한 전환 | old/beta stores 보존, backup 기반 수동 cutover와 rollback rehearsal 통과 | P21 guide walkthrough, P22 installed migration evidence |

## 4. Scope Guard

### In scope

- Windows 10/11 x64 및 Android API 24+ phone/tablet, portrait/landscape/split-screen.
- Rhythm clock와 Start/Pause/Resume/Stop for Today, Daily Rhythm와 Focus/Rest 설정, OS notification/sound delivery.
- Todo create/edit/complete/reopen/delete/reorder/date move와 Today/Calendar 화면.
- Korean/English, 11개 stable theme IDs, Windows custom MP3/volume/Mute, Android bundled default/Mute.
- Windows tray, close-to-tray, one instance, window state, packaged/unpackaged autostart.
- Android user-granted exact alarm, notification permission, background alarm, lifecycle recovery, restricted System Backup.
- plain JSON Portable Backup v1 export/import full replacement, recovery UI.
- independent Git repository, tests, CI definitions, README/setup/migration/release/privacy/notices, Windows ZIP/MSIX와 Android APK/AAB build paths.

### Out of scope

- browser fallback, Google Tasks/OAuth/sync, accounts, cloud sync, analytics, remote crash reporting, app-originated network.
- iOS는 macOS/Xcode/signing/device 환경 전까지, macOS/web/Linux release는 v1에서 제외합니다.
- Windows ARM64는 모든 plugin 검증 전까지 제외합니다.
- Android custom MP3/app volume, foreground service/permanent notification, inline notification action, full-screen intent, battery optimization exemption.
- system/light theme, proprietary Monokai Pro palette/name 재배포, source가 확인되지 않은 palette를 verified로 표기.
- backup merge/conflict resolution/password encryption, Neutralino private storage 직접 읽기, DB downgrade/reverse migration.
- in-app updater, Microsoft Store/Google Play enrollment·submission, signing key 생성/보관, remote 생성/push.
- old/beta executable/data/autostart 자동 삭제 또는 수정.

### Revisit triggers

- macOS/Xcode와 실제 iOS device/signing 환경이 준비되면 iOS ADR과 platform delivery 계획을 새로 작성합니다.
- 모든 required plugin이 Windows ARM64 release artifact에서 contract tests를 통과하면 ARM64 support ADR을 검토합니다.
- serialized Preferences/Todo contract가 실제로 바뀌면 v2 backup ADR, migration, dual codec을 추가합니다.
- Android 정책/API가 `SCHEDULE_EXACT_ALARM` 사용 또는 background callback을 막으면 사용자 동의 후 delivery architecture ADR을 새로 작성합니다. v1에서 foreground service를 암묵적으로 추가하지 않습니다.
- theme audit가 다른 palette의 재배포 근거를 확인하지 못하면 stable ID를 유지한 Compatibility Theme replacement를 적용하고 notice를 갱신합니다.
- Todo reminder, sync, account, Android custom sound가 새 목표가 되면 현재 context와 분리된 기능 결정이 필요합니다.

## 5. Architecture / System Model

### 5.1 Domain concepts and invariants

- **Daily Rhythm**: local wall-clock start/end로 정의되고 자정을 넘을 수 있습니다. start=end는 invalid이며 첫 Focus Interval보다 짧을 수 없습니다.
- **Focus/Rest Interval**: 각각 integer 1–180, 1–60분입니다. event cadence는 Start/Resume 시각이 아니라 Daily Rhythm start에 anchor됩니다.
- **Rhythm Event**: Focus 또는 Rest 경계이며 현재 시각 이전 missed event는 replay하지 않습니다.
- **Rhythm Session**: `idle`, `running`, `paused`, `stoppedForToday`. 창 밖 Start는 running intent를 유지하고 다음 window를 arm합니다. Pause는 anchor를 이동하지 않고, Stop for Today는 cross-midnight window start key로 다음 start까지 억제합니다.
- **Rhythm Settings Draft**: Focus/Rest/Daily Rhythm/Windows autostart의 device-local 미저장 상태입니다. Save 전 scheduling에 영향을 주지 않고 backup에서 제외됩니다.
- **User Preferences**: language/theme/sound/volume은 immediate, rhythm/autostart는 Save입니다. legacy `kor`는 Flutter `ko`로만 mapping합니다.
- **Todo**: stable ID, Todo Title, Local Calendar Date, optional Todo Time, completed, displayOrder, createdAt/updatedAt을 가집니다. time은 display-only입니다.
- **Completion Group**: 한 날짜의 incomplete/completed partition입니다. incomplete가 먼저이고 group 내부만 사용자 reorder가 가능합니다.
- **Portable Backup**: `Clock Rhythm` schema v1의 plain JSON replacement package이며 Preferences/Todos만 포함합니다.
- **Compatibility Theme**: legacy ID를 유지하면서 redistributable display name/palette를 선택합니다. `monokai-pro`는 `Neon Dusk`입니다.

### 5.2 Context and directory ownership

```text
lib/
|-- main.dart
|-- app/
|   |-- clock_rhythm_app.dart
|   |-- composition/                 # 유일한 concrete wiring/DI root
|   |-- navigation/                  # go_router route와 restoration
|   |-- presentation/                # shell, startup/recovery, platform chrome
|   `-- infrastructure/              # cross-context DB/native app adapters
|-- contexts/
|   |-- rhythm/
|   |   |-- domain/
|   |   |-- application/
|   |   |-- infrastructure/
|   |   |-- presentation/
|   |   |-- public.dart
|   |   |-- public_model.dart
|   |   `-- public_presentation.dart
|   |-- preferences/                 # 같은 layer/public surface 규칙
|   `-- todo/                        # 같은 layer/public surface 규칙
|-- features/
|   `-- data_transfer/               # Preferences/Todo 공개 계약 조율
|       |-- application/
|       |-- infrastructure/
|       |-- presentation/
|       `-- public.dart
|-- shared/
|   |-- i18n/
|   |-- time/
|   `-- ui/                          # domain-neutral primitive만
`-- l10n/                            # ARB와 generated localization
```

- Domain은 Application/Infrastructure/Presentation/Flutter/Drift/plugin을 참조하지 않습니다.
- Application은 Domain과 application port만 참조합니다.
- Infrastructure가 port를 구현하고 Presentation은 application public API/ViewModel만 사용합니다.
- context/feature는 `app`을 참조하지 않고 `shared`는 business module을 참조하지 않습니다.
- Preferences만 Rhythm의 공개 model을 사용할 수 있습니다. Rhythm은 Preferences를 직접 참조하지 않습니다.
- Data Transfer는 Preferences/Todo 공개 snapshot/use case만 사용하고 concrete DB repository를 deep import하지 않습니다.
- native Kotlin은 `android/app`, C++는 `windows/runner`에 최소로 남고 local plugin package로 승격하지 않습니다.

### 5.3 Public interfaces

| Owner | Public contract | Consumers | Hidden implementation |
| ----- | --------------- | --------- | --------------------- |
| Rhythm Domain/Application | configuration, schedule, session snapshot, Start/Pause/Resume/Stop/Reconcile, delivery ports | Rhythm presentation, Preferences rescheduler, app composition | platform alarms, tray, sound, `DateTime.now()` |
| Preferences | Preferences snapshot/commands, Draft, settings/autostart/sound ports | Preferences presentation, Data Transfer, app composition | Drift rows, shared_preferences, file paths, registry/StartupTask |
| Todo | Todo snapshot/commands/queries | Todo presentation, Data Transfer | Drift rows, ID algorithm |
| Data Transfer | export, prepare, preview, confirm, file/replacement/safety ports | Data page, recovery page, app composition | JSON DTO, file picker, cross-context transaction |
| App | router, startup state, platform presentation profile, composition root | `main.dart` | concrete plugin/native selection |
| Shared | Clock contract, i18n/formatting, domain-neutral UI primitive | all inward-safe consumers | business state |

Riverpod Notifier/AsyncNotifier가 feature presentation state와 provider-based DI를 소유합니다. text field focus, preview button animation, drag gesture 같은 transient state는 가장 가까운 StatefulWidget에 둡니다. provider가 domain rule을 다시 계산하거나 platform package type을 노출하지 않습니다.

### 5.4 Routes and presentation state

- `/clock`: clock/rhythm controls, rhythm settings, Today Todos.
- `/calendar?date=YYYY-MM-DD`: strict Local Calendar Date와 calendar/list.
- `/data`: Portable Backup export/import.
- `/theme`: 11개 theme 선택.
- `StatefulShellRoute.indexedStack`가 네 branch와 restoration scope를 소유합니다.
- Windows는 top segmented navigation과 `Ctrl+1`–`Ctrl+4`, Android는 bottom navigation을 사용합니다.
- Android back은 modal/detail → `/clock` → system exit 순서입니다. malformed date와 unknown route는 explicit localized error입니다.
- Windows first 920×680, min 720×560, device-local bounds/maximized restore와 monitor clamp를 사용합니다.
- layout은 device name/orientation이 아니라 available constraints로 compact 1-column 또는 useful 2-column을 선택합니다.

### 5.5 State transitions and data flows

#### Rhythm activation

```text
Idle --Start/capabilities granted--> Running(inside window or next window armed)
Idle --Start/capability denied------> Idle + rationale/settings action
Running --Pause---------------------> Paused + future delivery cancelled
Paused --Resume---------------------> Running + next future anchored boundary
Running/Paused --Stop for Today-----> StoppedForToday + current-window suppression
StoppedForToday --next window start-> Running + newly computed first boundary
Any --confirmed import/explicit Quit-> Idle + delivery/audio cancelled
```

- Windows는 process/tray가 살아 있는 동안 Dart scheduler가 event를 전달합니다. close는 hide, Quit은 stop입니다. ordinary/autostart launch는 Idle입니다.
- Android Start 시 Dart가 revisioned current+future occurrence queue를 계산하고 Kotlin이 earliest exact alarm과 atomic no-backup state를 저장합니다. receiver는 notification과 다음 precomputed alarm을 먼저 처리한 뒤 headless Dart가 queue를 보충합니다.
- late/sleep/time jump 후 P2 reconcile은 `now` 이전 event를 건너뜁니다. Android 9분 미만 값은 유효하지만 deep idle 지연/skip 경고가 있습니다.
- settings Save는 obsolete delivery를 cancel하고 새 schedule에서 future만 재계산합니다. Paused/Stopped 의미는 유지합니다.
- active Android language/Mute 변경은 occurrence timestamps를 유지한 채 payload를 새 revision으로 바꿉니다. Windows는 delivery 순간 최신 language/sound를 읽습니다.

#### Preferences and draft

```text
Durable Preferences -> edit rhythm/autostart -> Device Draft(dirty)
Device Draft --Discard--------------> Durable snapshot
Device Draft --Save valid/succeeds--> Durable Preferences -> reschedule/autostart reconcile
Language/theme/sound/volume command --> immediate durable change
Confirmed import -------------------> imported Durable Preferences + draft reset
```

- first successful rhythm Save 전 settings panel은 expanded입니다.
- Mute는 visible OS notification을 없애지 않습니다. Windows unmute는 previous default/custom+volume, Android는 bundled default를 복구합니다. 0%는 Mute가 아닙니다.

#### Todo and calendar

- create는 installation total 25,000 미만에서만 가능하고 target date의 incomplete group 끝에 놓입니다.
- complete/reopen은 displayOrder를 보존하고 group display가 바뀝니다.
- reorder는 같은 date+completion group 전체 순열만 받습니다.
- date move는 title/time/completion을 보존하고 target completion group 끝에 append합니다.
- delete는 confirm/undo/Snackbar 없이 즉시 permanent command입니다.
- Sunday-first 42-cell grid에서 adjacent-month 날짜는 blank입니다.
- local midnight/timezone update 때 selected date가 old today였던 경우만 new today를 따라갑니다.

#### Portable Backup import

```text
file stat/stream <=32MiB
  -> full JSON/envelope/value validation
  -> <=25,000 Todos/domain restoration
  -> redacted preview
  -> explicit confirmation
  -> cancel Rhythm/audio; session becomes Idle
  -> suspend mutating UI
  -> one Drift transaction replaces Preferences+Todos
  -> reconcile Windows autostart after commit
  -> refresh draft/queries or show typed failure
```

- validation/limit/cancel 단계는 session/data를 바꾸지 않습니다.
- confirmation 후 transaction이 실패해도 durable data는 이전 값, session은 Idle입니다.
- unknown additive fields는 받아들이고 export에서 drop; unknown schema version은 거부합니다.
- valid legacy custom sound preference는 bundled default로 sanitize합니다.

### 5.6 Storage and artifacts

| State/data | Windows | Android | Portable Backup | Android System Backup |
| ---------- | ------- | ------- | --------------- | --------------------- |
| Preferences | private Drift DB | private Drift DB | 포함 | D2D 및 encrypted-capable cloud만 포함 |
| Todos | private Drift DB | private Drift DB | 포함 | D2D 및 encrypted-capable cloud만 포함 |
| Rhythm Session/Alarm IDs | process memory only | atomic `noBackupFilesDir` | 제외 | 제외 |
| Custom MP3 | versioned private file | 지원 안 함 | binary/path 제외, default로 sanitize | 제외 |
| Draft/window state | replaceable device UI store | restoration/device UI store | 제외 | 제외 |
| Permission/channel/diagnostics | OS/no-backup state | OS/no-backup state | 제외 | 제외 |
| Release artifact | ZIP/MSIX | APK/AAB | 해당 없음 | 해당 없음 |

- Drift DB는 app-level encryption 없이 OS private storage에 둡니다.
- migration/corruption은 original DB를 보존하고 retry/import/confirmed reset recovery screen으로 갑니다.
- release logs에는 Todo title과 full custom path를 남기지 않습니다.
- Portable Backup은 readable plain JSON임을 사용자에게 경고합니다.

### 5.7 External dependencies and platform capabilities

- stable pub.dev release와 committed lockfile만 사용합니다. dependency upgrade는 별도 change로 supported matrix를 다시 실행합니다.
- 모든 plugin은 owned port와 contract test 뒤에 둡니다.
- Windows autostart는 ZIP의 HKCU Run + `--hidden`, MSIX StartupTask를 package-aware native adapter로 구분합니다.
- Android는 `SCHEDULE_EXACT_ALARM`, API 33+ notification permission을 user action으로 얻습니다. `USE_EXACT_ALARM`, full-screen, foreground service, battery exemption은 없습니다.
- release artifacts와 앱 내부에 dependency/theme/asset notices를 포함합니다.

### 5.8 Security, privacy, and failure behavior

- untrusted boundary인 backup/file picker/DB row/native channel/environment/signing config를 타입·크기·범위로 검증합니다.
- application 내부는 validated value object와 explicit result를 사용하고 실패를 삼키지 않습니다.
- DB/open/migration/import 실패는 silent reset/coercion/partial success가 아닙니다.
- OS side effect(autostart, alarms, notification, file adoption)는 DB transaction 밖에서 desired/actual/repair 상태로 추적합니다.
- signing keys/password는 source와 logs에 들어가지 않습니다.
- 앱은 계정, network, analytics, remote logging이 없습니다.

## 6. Milestone Index

P-ID는 안정적인 작업 식별자입니다. 실행 순서는 아래 dependency와 실행 wave를 따르며 제목 변경 시 ID를 재번호화하지 않습니다.

| Item | Purpose | Depends on | Parallelizable |
| ---- | ------- | ---------- | -------------- |
| [P0 - 독립 저장소와 고정 도구체인 부트스트랩](items/P0.md) | FVM/Flutter/platform shell/lockfile 준비 | - | false |
| [P1 - 컨텍스트 경계와 추적성 제어 확립](items/P1.md) | 디렉터리·공개 표면·architecture·182 behavior inventory | P0 | false |
| [P2 - Rhythm 도메인과 일정 계산 코어 작성](items/P2.md) | anchor schedule와 session 전이 | P1 | true |
| [P3 - Preferences 도메인과 Draft 적용 의미 작성](items/P3.md) | durable/immediate/draft 설정 계약 | P1, P2 | true |
| [P4 - Todo 도메인과 애플리케이션 동작 작성](items/P4.md) | Local Date, group order, CRUD/limit | P1 | true |
| [P5 - Drift 영속성·마이그레이션·복구 경계 작성](items/P5.md) | 단일 DB, repository, transaction/recovery | P2, P3, P4 | false |
| [P6 - Portable Backup v1 codec과 원자적 교체 흐름 작성](items/P6.md) | v1 strict validation/preview/replacement | P2, P3, P4, P5 | false |
| [P7 - 복원 가능한 앱 셸과 안정 route 작성](items/P7.md) | 네 route와 adaptive navigation | P1 | true |
| [P8 - 한국어·영어 localization과 24시간 표기 작성](items/P8.md) | ARB catalog와 format/failure mapping | P1 | true |
| [P9 - 테마·아이콘·기본음과 배포 고지 이관](items/P9.md) | 11 IDs, Compatibility Theme, assets/notices | P1, P3, P8 | true |
| [P10 - Preferences와 Rhythm Settings Draft 화면 작성](items/P10.md) | settings, draft, theme/sound/platform UI | P3, P5, P7, P8, P9 | false |
| [P11 - Todo 목록과 Calendar 화면 작성](items/P11.md) | Today/calendar/editor/reorder | P4, P5, P7, P8, P9 | true |
| [P12 - Clock과 Rhythm Session 화면 작성](items/P12.md) | clock ticker, controls, status composition | P2, P3, P5, P7, P8, P10, P11 | false |
| [P13 - Data Transfer와 데이터베이스 복구 화면 작성](items/P13.md) | file flow, preview/confirm, recovery | P5, P6, P7, P8, P10, P12 | false |
| [P14 - Windows 창·단일 인스턴스·트레이·자동 시작 작성](items/P14.md) | Windows lifecycle와 one-instance | P3, P5, P7, P12 | false |
| [P15 - Windows 알림과 알림음 전달 작성](items/P15.md) | toast/default/custom/mute/audio lifecycle | P3, P5, P8, P9, P10, P12, P14 | false |
| [P16 - Android exact alarm·권한·알림 전달 bridge 작성](items/P16.md) | permission gate와 native alarm delivery | P2, P3, P5, P8, P9, P12 | false |
| [P17 - Android lifecycle 복구와 System Backup 규칙 작성](items/P17.md) | reboot/time/process/backup recovery | P5, P16 | false |
| [P18 - 적응형 레이아웃·키보드·복원·접근성 강화](items/P18.md) | 전체 UI accessibility/adaptive hardening | P7–P17 | false |
| [P19 - CI·생성물·아키텍처 품질 게이트 작성](items/P19.md) | 공통 local/CI gate와 release build | P0, P1 | true |
| [P20 - beta·production identity와 배포 artifact 패키징](items/P20.md) | side-by-side ZIP/MSIX/APK/AAB | P9, P14–P17, P19 | false |
| [P21 - 설정·마이그레이션·운영·검증 가이드 작성](items/P21.md) | setup/cutover/rollback/release docs | P6, P13, P20 | true |
| [P22 - 행동 동등성 감사와 출시 자격 판정](items/P22.md) | 전체 behavior/platform/artifact evidence | P2–P21 | false |

### Recommended execution waves

1. Wave 0: P0.
2. Wave 1: P1.
3. Wave 2: P2, P4, P7, P8, P19를 경계가 겹치지 않는 작업자로 병렬 수행할 수 있습니다.
4. Wave 3: P3 후 P5, P9. P3는 P2의 public model이 고정된 뒤 시작합니다.
5. Wave 4: P6, P10, P11. P6은 P5 transaction 계약을 먼저 요구합니다.
6. Wave 5: P12.
7. Wave 6: P13, P14, P16은 P12 public command/snapshot이 고정된 뒤 서로 다른 platform/feature 경계에서 수행할 수 있습니다.
8. Wave 7: P15와 P17.
9. Wave 8: P18과 P20; P21은 P20 artifact가 확정된 뒤 진행합니다.
10. Wave 9: P22. 실패 cell은 owning P-item만 다시 열고 해당 downstream evidence만 재실행합니다.

## 7. Dependency Diagram

```text
P0 -> P1
P0, P1 -> P19

P1 -> P2
P1 -> P4
P1 -> P7
P1 -> P8
P2 -> P3

P2, P3, P4 -> P5
P1, P3, P8 -> P9
P2, P3, P4, P5 -> P6
P3, P5, P7, P8, P9 -> P10
P4, P5, P7, P8, P9 -> P11

P2, P3, P5, P7, P8, P10, P11 -> P12
P5, P6, P7, P8, P10, P12 -> P13
P3, P5, P7, P12 -> P14
P2, P3, P5, P8, P9, P12 -> P16

P3, P5, P8, P9, P10, P12, P14 -> P15
P5, P16 -> P17
P7..P17 -> P18

P9, P14, P15, P16, P17, P19 -> P20
P6, P13, P20 -> P21
P2..P21 -> P22
```

## 8. ADR Traceability and Missing-Work Prevention

| ADR | Decision coverage | Owning items |
| --- | ----------------- | ------------ |
| 0001 | 전체 제품 범위, 제외 범위 | P2–P18, P22 |
| 0002 | explicit JSON migration, isolated beta, source read-only | P0, P6, P20, P21, P22 |
| 0003 | Windows/Android native delivery, iOS defer | P14–P17, P20, P21 |
| 0004 | Daily Rhythm anchor와 session semantics | P2, P12, P16, P17 |
| 0005 | Dart context/layer/public boundary | P1, P5, P19 |
| 0006 | Riverpod/Drift/go_router foundation | P0, P1, P5, P7, P10–P13 |
| 0007 | Portable Backup v1 유지와 transaction/side effect | P3, P5, P6, P13, P21, P22 |
| 0008 | 네 stable route와 restoration/back/error | P7, P18 |
| 0009 | Todo Local Calendar model/order/calendar | P4, P11 |
| 0010 | defaults, draft/immediate preference, mute | P3, P10, P12, P15, P16 |
| 0011 | local/private/recoverable data, System Backup | P5, P6, P13, P17, P21, P22 |
| 0012 | user-granted exact alarm, Android policy | P2, P10, P16, P17, P22 |
| 0013 | identity/platform/artifact/version/signing | P0, P9, P20, P22 |
| 0014 | window, adaptive, 1Hz, accessibility, keyboard | P7, P9–P12, P14, P18 |
| 0015 | draft persistence, 24-hour time, MP3 lifecycle, payload refresh | P3, P8, P10, P15, P16 |
| 0016 | legacy behavior, layered tests, platform evidence/gates | P1–P22, 특히 P18/P19/P22 |
| 0017 | explicit reversible cutover/coexistence | P6, P14, P20, P21, P22 |
| 0018 | pinned toolchain/plugin ports/native state/autostart | P0, P1, P5, P14–P17, P19, P20 |
| 0019 | stable theme IDs, license compatibility, asset risk | P3, P9, P20, P22 |
| 0020 | one Windows instance와 one active notification | P14, P15, P16, P20, P22 |
| 0021 | backup byte/Todo/envelope/item/preview hardening | P4, P6, P13, P22 |
| 0022 | staged work, separate tooling, CI/native locality/deliverables | P0, P1, P19–P22 |
| 0023 | local civil cadence, DST gap/fold, stale delivery watermark | P2, P15, P16, P22 |

누락 방지 방식:

- P1에서 source commit SHA, 49 test files, 182 executable test titles를 `docs/verification/legacy-behavior-matrix.md`에 고정하고 모든 행에 owning P-item을 배정합니다.
- 각 P-item은 자기 source behavior 행에 Dart/native/manual evidence 경로를 추가하고 status를 갱신합니다.
- master index가 23개 item을 모두 링크하며 P-item 상세의 SSOT는 각 `items/P*.md`입니다.
- 청크 실패 시 해당 P-item만 `In Progress`로 되돌리고 downstream artifact/evidence hash만 무효화합니다. 완료된 독립 domain fixture와 다른 platform evidence는 재작성하지 않습니다.
- 최종 병합은 P22에서 behavior matrix, ADR traceability, platform matrix, artifact manifest를 교차 검사합니다.
- 진행 상태와 중단/재개 지점은 [실행 컨텍스트 ledger](execution-ledger.md)에 기록합니다. 숨겨진 추론은 기록하지 않고 observable command/result/artifact/status만 남깁니다.

## 9. Regression Matrix

| Scenario | Setup | Action | Expected result | Locked by |
| -------- | ----- | ------ | --------------- | --------- |
| 기본 Preferences | fresh DB | 첫 실행 | 50/10, 05:00–18:00, kor/current/default, autostart off, setup false | P3, P5, P10 |
| 창 안 Start | 05:00 anchor, 현재 06:07 | Start | Start+50이 아니라 anchor sequence의 다음 future boundary | P2, P12 |
| 창 밖 Start | 현재 Daily Rhythm 밖 | Start | 다음 window first boundary를 arm하고 Running intent 표시 | P2, P12 |
| Pause/Resume | active schedule | 오래 Pause 후 Resume | anchor는 이동하지 않고 missed skip 후 다음 future event | P2, P12 |
| Stop cross-midnight | 22:00–02:00 창 | 00:30 Stop | 같은 22:00 window 끝까지 억제, 다음 22:00에 자동 해제 | P2, P17 |
| Running settings Save | active session+valid draft | Save | obsolete delivery 취소, new anchor future-only; paused/stopped 의미 보존 | P2, P3, P10 |
| Draft restoration | unsaved settings | route/tray/config/process restore | dirty draft 복원, active config 불변 | P3, P10 |
| Mute/0% | visible notification enabled | toggle Mute/volume 0 | 둘 다 알림 표시; Mute만 sound 없음, 0% warning | P3, P10, P15 |
| Todo title/date | emoji/한글, invalid leap date | create/import | grapheme 1–160과 Gregorian date만 수용 | P4, P6, P11 |
| Todo ordering | mixed completion/time | list/toggle/reopen | incomplete→completed, group displayOrder; time은 정렬 안 함 | P4, P11 |
| Todo reorder/move | 여러 그룹/날짜 | drag, semantic move, date change | same-group only; target completion group 끝 append | P4, P11 |
| Todo delete | existing Todo | Delete | 즉시 영구 삭제, dialog/undo/Snackbar 없음 | P4, P11 |
| Todo limit | 25,000 existing | create/import 25,001 | session/data 변화 전 localized failure | P4, P6, P11 |
| Calendar | 임의 month/locale | open/navigate | Sunday-first 42 cells, adjacent blank, localized labels | P8, P11 |
| Midnight selection | selected old today 또는 다른 date | local midnight/timezone change | old today만 new today follow, explicit date 유지 | P4, P11, P17 |
| Route/back | 각 route와 invalid date | navigate/back/deep link | stable route/state; Android secondary→clock; invalid error | P7, P18 |
| Clock visibility | clock visible/offstage | time advance/return | visible subtree만 1Hz, offstage stop, return immediate reconcile | P12, P18 |
| Backup valid round trip | Neutralino v1 | prepare/confirm/export | semantic-equal Preferences/Todos, v1 유지, custom default sanitize | P6, P13, P22 |
| Backup invalid item | index N invalid | prepare | whole reject, indexed localized error, title/log 없음 | P6, P13 |
| Import transaction fault | valid confirmed file | injected DB fault | old durable data, session Idle, no partial state | P5, P6, P13 |
| DB migration/corruption | bad fixture | startup | original file 보존, recovery page, no silent empty DB | P5, P13 |
| Windows close/tray | Running | close/open/pause/quit | hide+continue, tray command, Quit stop+exit | P14, P15 |
| Windows second instance | existing hidden/visible | interactive or `--hidden` launch | interactive focus, hidden no surface, one process | P14, P20 |
| Windows autostart | ZIP/MSIX, beta/prod | enable/reboot/launch | exact identity, hidden+Idle, actual/repair state | P3, P14, P20 |
| Custom MP3 ownership | valid selected source | select then source delete | private copy plays once; backup/path exclusion | P9, P15 |
| Custom MP3 failure | corrupt/new or later decode fault | select/event | adopt 거부 또는 bundled fallback+repair, old pref 보존 | P15 |
| Android denied Start | permission/exact missing | Start then grant | Idle+rationale; grant alone does not Start | P10, P16, P17 |
| Android process removal | active registered session | remove recent/process then event/reopen | notification continues; reopen Running | P16, P17 |
| Android reboot/update/time | active+permitted | OS event | Dart recompute, stale revision cancel, next future event | P16, P17 |
| Android force-stop/revoke | active session | force-stop/revoke/grant | no automatic recover; next foreground explains/action | P16, P17 |
| Android deep idle | <9-minute term | Doze | warning; OS delay accepted; missed events skipped, no replay | P2, P10, P16, P22 |
| Android payload refresh | active session | language/Mute change | same occurrence times, new localized/sound payload | P3, P8, P16 |
| System Backup | durable+transient state | backup/restore | Preferences/Todos only under allowed transport; transient excluded | P5, P17 |
| Theme compatibility | all v1 IDs | import/render | all resolve; `monokai-pro`→Neon Dusk; notices present | P6, P9, P22 |
| Accessibility | ko/en, themes, 200%, keyboard | main flows | no overflow; 48dp; labels/focus/contrast/non-color; no 1Hz live speech | P18 |
| Side-by-side cutover | old+beta+prod | export/import/install | stores/autostart independent; custom reselect; rollback retained | P20, P21, P22 |
| Installed update | prior beta/prod DB | install newer artifact | data retained/migrated or recovery; no silent reset | P5, P20, P22 |
| Privacy/log/network | release build | full flow/traffic capture | no app network; no titles/full paths/secrets in logs/artifacts | P5, P6, P17, P20, P22 |

## 10. Side Effect Review

| Area | Risk | Mitigation | Verification |
| ---- | ---- | ---------- | ------------ |
| Workstation provisioning | 자동 설치·license 수락·환경 오염 | P0 preflight는 read-only 진단, 설치/수락은 사용자 작업 | `flutter doctor -v`, installed component checklist |
| Source repository | 원본 code/untracked file 변경 | sibling source read-only; target 독립 Git; before/after status | source `git status --short`, target diff |
| Portable Backup import | 현재 data 전체 교체 | preflight→preview→confirm, DB transaction, recovery copy | P5/P6 failure injection, P13 flow |
| Rhythm import safety | 실패 import인데 old schedule 계속 울림 | confirm 시 schedule/audio 먼저 cancel, 항상 Idle | P6 command-order test |
| Windows autostart | stale/beta-prod collision | flavor exact registration, post-commit reconcile, repair state | registry/StartupTask inspection |
| Windows single instance | 중복 알림/process | pre-engine per-flavor mutex와 activation message | multi-process harness |
| Custom media | old valid sound loss/path disclosure | versioned adoption, decoder validate, pointer commit, redacted logs | fault file tests/log scan |
| Android permissions | 사용자 의사 없는 start | Start gate, explicit settings, grant alone no start | API permission matrix |
| Android alarms | 중복/stale/끊김 | revisioned atomic state, one alarm, precomputed queue, headless refill | native race/process tests |
| Android backup | stale session/device path restore | allowlist durable DB, no-backup transient state | backup XML and restore inspection |
| Signing | key/password 유출 또는 fake signed artifact | external inputs, ignore, clear fail, signature inspection | secret scan, artifact verifier |
| Packaging | ZIP/runtime 누락, update data loss | staging manifest/checksum, clean install/update | P20/P22 clean-machine evidence |
| Theme/assets | 재배포 위반·거짓 provenance | license audit, Compatibility Theme, explicit asset notice | notices review/artifact scan |
| Privacy | title/path/network leakage | local only, redacted structured logs, no network dependency | traffic/log/dependency scan |

## 11. Verification Commands / Checks

- Environment prerequisite:
  - Command/check: `powershell -ExecutionPolicy Bypass -File tool/preflight.ps1`
  - Expected: FVM Flutter 3.44.7, Windows C++ toolchain, Android SDK/API 36, doctor 상태를 항목별로 보고하고 누락 시 nonzero; 자동 설치/수락 없음.
- Generated sources:
  - Command/check: `powershell -ExecutionPolicy Bypass -File tool/generate.ps1` 후 `tool/check_generated.ps1`
  - Expected: Drift와 gen_l10n output이 source와 일치하고 clean tree에서 diff 없음.
- Common quality gate:
  - Command/check: `powershell -ExecutionPolicy Bypass -File tool/verify.ps1`
  - Expected: format, analyze, architecture, all Dart/Flutter tests, native unit tests가 순서대로 green.
- Architecture only:
  - Command/check: `fvm dart run tool/check_architecture.dart`
  - Expected: inward dependency와 public-surface 위반 0개.
- Flutter suites:
  - Command/check: `fvm flutter test --reporter expanded`
  - Expected: domain/application/infrastructure/widget/restoration/golden/accessibility tests green.
- Android native suites:
  - Command/check: `Push-Location android; .\gradlew.bat testDebugUnitTest; Pop-Location`
  - Expected: bridge/state/permission/lifecycle unit tests green.
- Windows beta artifact:
  - Command/check: `powershell -ExecutionPolicy Bypass -File tool/package_windows.ps1 -Flavor Beta -Artifact Zip`
  - Expected: verified portable ZIP, content manifest, checksum.
- Android beta artifact:
  - Command/check: `powershell -ExecutionPolicy Bypass -File tool/package_android.ps1 -Flavor Beta -Artifact Apk`
  - Expected: API/ABI/ID/version/signature가 확인된 beta APK.
- Production artifacts:
  - Command/check: 같은 scripts에 `-Flavor Production -Artifact Msix|AppBundle`과 external credential.
  - Expected: credential이 있으면 signed artifact; 없으면 명확한 실패이며 fallback signing 없음.
- Artifact inspection:
  - Command/check: `powershell -ExecutionPolicy Bypass -File tool/verify_artifact.ps1 -Path <artifact>`
  - Expected: identity/version/files/assets/signature/checksum이 expected manifest와 일치.
- Release evidence:
  - Command/check: `powershell -ExecutionPolicy Bypass -File tool/check_release_evidence.ps1`
  - Expected: behavior matrix orphan 0, 필수 platform cell 누락 0, evidence/artifact hash 일치. 하나라도 없으면 nonzero/beta 판정.
- Manual checks:
  - Windows 10/11 x64 physical/VM에서 tray/window/autostart/custom audio/install/update.
  - Android API 24/31/33/36 emulator와 physical device에서 permission/exact alarm/process removal/reboot/Doze/time/timezone/backup/install-update.
  - TalkBack/Narrator와 actual Neutralino v1 → beta → production round trip.

## 12. Handoff Context

- Current status: planning only. Flutter source, Git repository, toolchain installation, package resolution, builds는 아직 시작하지 않았습니다.
- Key decisions:
  - full behavioral/data parity, Windows+Android first, independent beta/prod identities.
  - Daily Rhythm anchored scheduling, local-only Todo, explicit v1 replacement backup.
  - Riverpod + Drift + `go_router`, context boundaries, platform ports, minimal app-local native code.
  - exact alarm requires user permission; no foreground service; Windows close-to-tray/one-instance.
  - all 11 theme IDs 유지, `monokai-pro`→`Neon Dusk`, source icon/audio reuse with undocumented-provenance notice.
- Watchouts:
  - P0 external tooling is currently absent and must not be silently provisioned.
  - P16 headless Dart refill is a release-critical hypothesis until physical evidence exists.
  - import confirmation has intentional non-transactional side effect: session/audio becomes Idle even if DB replacement fails.
  - P20 signing/store work must not leak credentials or imply store submission.
- Next operator starts from:
  - Read this file, [P0](items/P0.md), [execution-ledger.md](execution-ledger.md), `CONTEXT.md`, ADR 0018/0022.
  - Run only P0 preflight first. If toolchain is missing, record a user intervention request and stop before Flutter project generation.
- Do not do:
  - Do not modify the Neutralino source repository or its untracked files.
  - Do not auto-install tooling, auto-accept licenses, create/push a remote, add secrets, submit stores, or delete old/beta data.
  - Do not skip a P-item dependency, mark production complete without P22 evidence, or replace an accepted ADR silently.
- Context ledger:
  - Every P-item start/completion/blocker, command/result summary, artifact path/hash, cancellation/resume point, user intervention must be added to [execution-ledger.md](execution-ledger.md).

## 13. Self-Audit Before Final

- [x] 모든 Success Criteria가 검증 방법을 가집니다.
- [x] 모든 P-item이 독립된 `items/P{number}.md` 파일 하나에만 존재합니다.
- [x] `plan.md`가 모든 P-item을 상대 링크로 참조하고 상세 실행 계약을 중복하지 않습니다.
- [x] 모든 P-item이 parent plan, dependency, risk, rollback, validation을 가집니다.
- [x] 모든 P-ID가 유일하고 dependency는 실제 P-item을 가리킵니다.
- [x] orphan P-item과 milestone 누락이 없도록 자동 검증 대상으로 지정했습니다.
- [x] 모든 중요한 제약이 Scope Guard와 ADR traceability에 반영되었습니다.
- [x] source 49/182 executable inventory와 ADR 22개를 이용한 누락 방지 전략이 있습니다.
- [x] 핵심 domain/UI/platform/data/migration/privacy 회귀 행렬이 있습니다.
- [x] 로컬·CI·artifact·physical release 검증 명령과 체크가 있습니다.
- [x] hidden reasoning을 저장하거나 노출하지 않습니다.
- [x] 불확실성은 Assumption/Open Question/Revisit Trigger로 분리했습니다.
- [x] 다음 작업자가 P0부터 바로 실행하고 중단/재개할 수 있습니다.
