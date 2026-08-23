# Clock Rhythm Flutter Port Execution Ledger

Parent plan:

- [전체 계획](plan.md)

## State

- Overall state: Implementation complete; Beta qualified; production release evidence incomplete
- Active P-item: P22 external production qualification
- Last completed P-item: P21
- Last updated: 2026-08-23 Asia/Seoul
- Next action: Windows 10 및 clean-user 설치, Android physical device lifecycle, installed-update, TalkBack/Narrator와 signed MSIX/AAB 증거를 최종 artifact hash에 묶어 채웁니다.
- Blocking condition: 로컬 구현 blocker는 없습니다. Production 자격에는 외부 signing material, 별도 Windows 10 환경, Android physical device가 필요합니다.

## Context snapshot

- Goal: Neutralino Clock Rhythm 전체 제품을 Windows 10/11 x64와 Android API 24+ Flutter 앱으로 포팅합니다.
- Source reference: `C:\Users\wndls\projects\clock-app`; read-only 기준 SHA `f05a7a4b3349fec7c129d2a2a6a6cf4be1de8db9`.
- Target repository: `C:\Users\wndls\projects\clock-app-flutter`; 독립 `main` Git 저장소, baseline commit `cb53d42523d1a4b2b4845e9990e5ff2ded04302b`, Flutter 3.44.7 Windows/Android shell.
- Decision sources: `CONTEXT.md`, `docs/adr/0001`–`0023`, [master plan](plan.md).
- Quality gate: P22의 behavior/platform/artifact evidence가 없으면 beta이며 production parity를 주장하지 않습니다.
- Prohibited side effects: source write, automatic tool/license provisioning, remote/push, secret commit, old/beta data 삭제, store submission.

## Plan status

| Item | Status | Owner | Started | Completed | Evidence summary |
| ---- | ------ | ----- | ------- | --------- | ---------------- |
| P0 | Done | Codex | 2026-08-22 | 2026-08-22 | common gate, Windows/Android debug build, Windows process, API 24·36 install/start/semantics 통과 |
| P1 | Done | Codex | 2026-08-22 | 2026-08-22 | 공개 표면 14개, architecture fixture 46개, source 49파일/182행 matrix, 전체 gate 통과 |
| P2 | Done | Codex | 2026-08-22 | 2026-08-22 | 순수 Domain/Application 65 tests, LB-101–115 Verified, DST 격리 probe, 전체 gate 통과 |
| P3 | Done | Codex | 2026-08-22 | 2026-08-23 | Preferences domain/use cases, draft, platform repair live state와 flavor-isolated device state 통과 |
| P4 | Done | Codex | 2026-08-22 | 2026-08-23 | Todo value/domain/order/limit와 application tests 통과 |
| P5 | Done | Codex | 2026-08-22 | 2026-08-23 | Drift migration, corruption recovery, atomic replacement와 rollback journal 통과 |
| P6 | Done | Codex | 2026-08-22 | 2026-08-23 | v1 codec, indexed invalid-field matrix, preview/confirm/replacement ordering 통과 |
| P7 | Done | Codex | 2026-08-22 | 2026-08-23 | router 재생성 뒤 선택 branch, calendar query와 branch state를 함께 복원하는 process-restoration 회귀 통과 |
| P8 | Done | Codex | 2026-08-22 | 2026-08-23 | ko/en catalog, generated localization, 24-hour formatting과 runtime refresh 통과 |
| P9 | Done | Codex | 2026-08-22 | 2026-08-23 | 11 theme IDs, contrast/goldens, icon/audio/notices와 package inclusion 검사 통과 |
| P10 | Done | Codex | 2026-08-22 | 2026-08-23 | Preferences/Rhythm draft, restoration, platform-specific controls와 repair UI 통과 |
| P11 | Done | Codex | 2026-08-22 | 2026-08-23 | Today/Calendar editor, reorder, keyboard/semantics와 scroll restoration 통과 |
| P12 | Done | Codex | 2026-08-22 | 2026-08-23 | clock ticker, Rhythm controls/status, failure/announcement와 runtime composition 통과 |
| P13 | Done | Codex | 2026-08-22 | 2026-08-23 | Data Transfer 및 DB recovery가 parse→preview→confirm→replace 순서와 retry를 보존 |
| P14 | In Progress | Codex | 2026-08-22 | - | Windows 11 native lifecycle/autostart harness 통과; Windows 10·installed autostart evidence 필요 |
| P15 | In Progress | Codex | 2026-08-22 | - | Windows notification/audio/tray adapters와 tests 통과; 실제 toast/custom audio/Narrator evidence 필요 |
| P16 | In Progress | Codex | 2026-08-22 | - | Android flavor별 native delivery와 43 tests 통과; emulator/physical delivery matrix 필요 |
| P17 | In Progress | Codex | 2026-08-22 | - | startup recovery/lifecycle/backup allowlist 구현 통과; reboot/Doze/transport 실증 필요 |
| P18 | In Progress | Codex | 2026-08-22 | - | 48dp/200%/keyboard/focus/semantics/contrast/goldens 통과; TalkBack/Narrator와 device layout evidence 필요 |
| P19 | Done | Codex | 2026-08-22 | 2026-08-23 | FVM/generated/docs/format/architecture/analyze/582 tests와 pinned CI/package scripts 통과 |
| P20 | In Progress | Codex | 2026-08-22 | - | Windows native/Dart flavor 정렬, runtime identity fail-closed, beta/prod portable 격리와 beta ZIP/APK 검사 통과; signed MSIX/AAB·clean install/update evidence 필요 |
| P21 | Done | Codex | 2026-08-22 | 2026-08-23 | setup/migration/release/privacy/troubleshooting/checklist와 74-document link/path gate 통과 |
| P22 | In Progress | Codex | 2026-08-23 | - | beta evidence gate, API 24/31/33/36 debug E2E, 실제 Neutralino → beta → production v1 왕복 통과; production physical/install/signing/accessibility evidence 미완료 |

## Observable events

숨겨진 추론은 기록하지 않습니다. 실행자가 관찰한 command, result, 상태 변화, 사용자 결정을 한 줄씩 추가합니다.

| Timestamp | P-item | Event | Command/tool | Result summary | Next action |
| --------- | ------ | ----- | ------------ | -------------- | ----------- |
| 2026-08-22 | Plan | Plan bundle created | documentation | 23 P-items와 dependency/verification 계약 작성 | P0 preflight |
| 2026-08-22 | P0 | Execution started | plan/ADR/source inspection | 대상은 Git/Flutter 미생성, 원본 SHA `f05a7a4b3349fec7c129d2a2a6a6cf4be1de8db9`, 원본에 기존 untracked 문서 1개 확인 | read-only toolchain probe |
| 2026-08-22 | P0 | Toolchain prerequisite blocked | `fvm --version`; `fvm flutter --version`; `fvm flutter doctor -v` | 세 명령 모두 `fvm` 미탐지로 exit code 1; 자동 설치·license 수락·Flutter 생성 없음 | 사용자 도구체인 준비 후 P0 재개 |
| 2026-08-22 | P0 | Execution resumed | user instruction | 사용자가 차단 해소와 구현 계속을 지시 | 사용자 범위 도구 설치 |
| 2026-08-22 | P0 | FVM and Flutter installed | official FVM 4.1.2 archive; `fvm install 3.44.7` | FVM archive SHA-256 `9a18b4daac98dac3c3230ff67ccc644d5a7875d1fc09fb7d848cb2900b9478b8`; Flutter 3.44.7/Dart 3.12.2 setup 성공 | project pin |
| 2026-08-22 | P0 | Windows toolchain installed | Visual Studio Installer modify | C++ workload, MSVC 14.44.35207, Windows SDK 10.0.26100.0, CMake 확인; installer exit code 0 | Android toolchain |
| 2026-08-22 | P0 | Target repository initialized | `git init -b main` | 독립 Git 저장소 생성, remote 없음, 기존 문서 보존 | FVM project pin |
| 2026-08-22 | P0 | Flutter version pinned | `fvm use 3.44.7 --force --skip-pub-get` | 일반 토큰 symlink 오류 1314를 관리자 1회 실행으로 해소; `.fvmrc`와 SDK link 생성 | doctor |
| 2026-08-22 | P0 | Partial doctor passed | `fvm flutter doctor -v` | Flutter 3.44.7, Windows 11, Visual Studio Build Tools green; Android SDK만 `[X]` | explicit Android license acceptance |
| 2026-08-22 | P0 | Android SDK license accepted | user instruction | 사용자가 Android SDK License Agreement 동의와 `sdkmanager --licenses` 진행을 명시적으로 허용 | Android toolchain install |
| 2026-08-22 | P0 | Android toolchain installed | Android Studio 2026.1.3.8, SDK Manager | SDK/API 24·35·36, Build Tools 36.0.0, emulator, NDK 28.2.13676358, CMake 3.22.1, API 24·36 AVD 준비; licenses accepted | Flutter shell generation |
| 2026-08-22 | P0 | Flutter shell generated | `fvm flutter create --platforms=windows,android ...` | 48개 기존 문서 aggregate SHA-256 `02bcaa52b2fbbdbbcc103bddb9a739140fc085fc90c89e4c675c7b415afda519` 생성 전후 동일 | metadata and smoke implementation |
| 2026-08-22 | P0 | Dependency contract locked | `fvm flutter pub get` | core/plugin 직접 의존성과 compatible `build_runner 2.15.1`/`drift_dev 2.34.0` lock; Git dependency 0 | verification |
| 2026-08-22 | P0 | Common gate passed | `tool/verify.ps1` | doctor no issues, format 5 files unchanged, analyze no issues, smoke 1/1 passed | platform builds |
| 2026-08-22 | P0 | Platform builds passed | `flutter build windows --debug`; `flutter build apk --debug` | `clock_rhythm.exe`와 `app-debug.apk` exit code 0 | runtime smoke |
| 2026-08-22 | P0 | Runtime smoke passed | Windows process; ADB API 24/36 | Windows process alive; 두 API에서 install success, Activity OK, `Clock Rhythm` semantics 확인 | P0 complete |
| 2026-08-22 | P1 | Execution started | plan/dependency review | P0 완료와 source SHA `f05a7a4b3349fec7c129d2a2a6a6cf4be1de8db9` 확인 | parallel matrix/boundary work |
| 2026-08-22 | P1 | Legacy count corrected | TypeScript AST inventory | 49 files/182 executable cases; 역사적 183은 `RegExp.test()` 정규식 오탐으로 확인되어 ADR 0016·plan·P1/P22 정정 | matrix generation resume |
| 2026-08-22 | P1 | Legacy behavior matrix completed | matrix validation | 182 stable unique IDs, 49 unique source files, 모든 행에 planned P-item과 Pending evidence type 기록 | architecture integration |
| 2026-08-22 | P1 | Architecture boundary hardened | independent review + Dart AST fixtures | module별 공개 표면, inward layer, shared 방향, Data Transfer narrowed contract, conditional platform branch, source-root containment을 46개 architecture test로 고정 | full gate |
| 2026-08-22 | P1 | Common gate passed | `tool/verify.ps1` | doctor green, format 23 unchanged, production architecture 18 files, analyze green, architecture 46 + smoke 1 = 47 tests passed | P1 complete |
| 2026-08-22 | P2 | Execution started | P2/ADR/source behavior review | P1 dependency 완료; legacy P2 behavior 15행과 개선된 schedule/session 계약 확인 | failing domain tests |
| 2026-08-22 | P2 | Failing tests confirmed | `flutter test test/contexts/rhythm` | 7개 test file이 아직 없는 Domain/Application 타입 때문에 의도대로 compile 실패 | value objects |
| 2026-08-22 | P2 | Rhythm core implemented | focused Domain/Application tests | ClockTime, Duration, Daily window, Configuration, Schedule, Session과 6 use case/3 port를 작성하고 P2 tests 65개 통과 | independent review |
| 2026-08-22 | P2 | Review findings corrected | read-only domain/application reviews | DST civil cadence, stale Stop reschedule, occurrence watermark, rollover-before-command, UTC boundary와 public window export 회귀 추가 | DST probe |
| 2026-08-22 | P2 | DST gap probe passed | Dart JS probe under Node `TZ=America/New_York` | 2026-03-08 `01:30 + 120 wall-clock minutes`가 `03:30`으로 계산됨; 임시 source 제거 | traceability |
| 2026-08-22 | P2 | Legacy evidence linked | `legacy-behavior-matrix.md` validation | LB-101–LB-115 15행 모두 실제 Dart test title과 `Verified 2026-08-22`로 연결 | full gate |
| 2026-08-22 | P2 | Common gate passed | `tool/verify.ps1` | doctor green, format 48 unchanged, production architecture 35 files, analyze green, all 112 tests passed | P2 complete checkpoint |
| 2026-08-23 | Resume | Prior task and repository state reconstructed | linked Codex task, ADR 0001–0023, plan/ledger/P0–P22, source/test/native audit | 세 read-only 감사 역할을 사용해 domain, platform, quality/release gap을 교차 확인; source mutation 경합 보고서 1개 보존 | composition repair |
| 2026-08-23 | P2/P5/P6/P13 | Missing regressions and destructive-flow boundary corrected | focused red→green tests | durable DST gap/fold test, Todo invalid-field index matrix, SQLite `-journal` rollback, DB recovery parse→preview→confirm→replace와 retry 추가 | runtime composition |
| 2026-08-23 | P3/P12/P14–P17 | Real platform composition restored | app/runtime/platform focused suites | placeholder entrypoint 제거, Windows/Android platform bootstrap, live repair state, Android startup recovery, Windows tray/window/notification/audio binding 통과 | accessibility/package waves |
| 2026-08-23 | P18 | Accessibility automation completed | accessibility/golden/presentation suites | 48dp, 200% text, keyboard/focus, Escape, process scroll restoration, semantics, 11-theme contrast와 대표 goldens 통과 | common gate |
| 2026-08-23 | P19/P21 | Windows PowerShell compatibility failure found | `tool/verify.ps1 -Platform All` | Windows PowerShell 5.1의 `Path.GetRelativePath` 부재로 docs gate 실패; repository-relative path 계산과 external-command stderr 수집을 5.1 호환 방식으로 교체 | rerun gate |
| 2026-08-23 | P19 | Common gate passed | `tool/verify.ps1 -Platform All` | doctor green, docs 69 links, generated 4 current, format 320 unchanged, architecture 225, analyze 0, all 538 tests passed | platform packages |
| 2026-08-23 | P20 | Windows beta package passed | `tool/package_windows.ps1 -Flavor Beta -Artifact Zip` | native autostart/lifecycle harness와 archive inspection 통과; SHA-256 `19c0f45f7610c96344e81a1765ac743839aa24c82bc522d54e33a76b4f4962a8` | Android package |
| 2026-08-23 | P20 | Android beta signing dependency defect corrected | beta package red→green, production fail-closed probes | beta가 production signing validation을 잘못 의존한 task graph 수정; production MSIX/AppBundle은 credential 부재 시 명확히 실패 | APK inspection |
| 2026-08-23 | P16/P20 | Android beta package passed | `tool/package_android.ps1 -Flavor Beta -Artifact Apk` | 43 native tests, API 24/36, Arm32/Arm64/x64, development signature와 archive inspection 통과; SHA-256 `f64ea05c30eb7ac2d18ad5b6d77452fff9b87b8189e5dc6f31cd21514aacba00` | evidence audit |
| 2026-08-23 | P22 | Legacy traceability audited | matrix integrity + 48 Dart evidence files + Windows harness | 182 IDs/49 source files 유지, 127 Verified/55 Pending; 느슨한 4개 mapping은 Pending으로 복원 | release decision |
| 2026-08-23 | P22 | Beta evidence gate passed, production blocked | `check_release_evidence.ps1 -ReleaseTier Beta|Production` | beta artifact/hash/common gate complete; production은 55 Pending legacy와 physical/install/signing/cutover evidence 때문에 nonzero | external evidence collection |
| 2026-08-23 | P7 | Process restoration completed | router-owning restoration widget regression | router 재생성 뒤 `/calendar?date=2026-08-23`, 선택 branch와 branch 입력 상태가 함께 복원됨 | legacy evidence closure |
| 2026-08-23 | P10/P12 | Rhythm settings parity gaps corrected | preferences presentation/domain suites | draft 기준 다음 알림·일일 범위 경고, accessible 24-hour picker와 deterministic clock ownership을 추가 | import integration |
| 2026-08-23 | P5/P6/P11/P13 | Durable import integration corrected | real Drift runtime integration | import 뒤 mounted Preferences/Todo가 durable replacement를 다시 읽고, visibility callback과 Todo date clock ownership 회귀를 잠금 | evidence audit |
| 2026-08-23 | P22 | Legacy evidence closed | evidence checker + 182-row audit | 49 files/182 rows, 160 Verified/22 ADR-backed Dispositioned/0 Pending; 누락·중복·잘못된 owner/path를 checker가 차단 | platform harness |
| 2026-08-23 | P17/P18/P22 | Manual evidence harnesses added | Android ADB harness + accessibility checklist | artifact hash·redacted device ID를 기록하며 API 24/36 InstallSmoke는 operator assessment 전까지 Passed로 승격하지 않음 | final gate |
| 2026-08-23 | P19/P20/P22 | Final beta checkpoint passed | `tool/verify.ps1 -Platform All`; package/evidence scripts | docs 70, generated 4, format 324, architecture 226, analyze 0, Flutter 578 + Android native 43 tests; beta exit 0, production exit 1 for external evidence/artifacts only | external evidence collection |
| 2026-08-23 | P19/P22 | Android emulator E2E added and stabilized | API 36·24 dedicated AVD + `integration_test/app_e2e_test.dart` | 실제 Android composition에서 Drift Todo create/re-read, Calendar 이동과 Back 통과; API 36 clean 연속 2회 및 final snapshot 1회, API 24 1회 통과 | release rebuild |
| 2026-08-23 | P19/P20 | E2E-to-release mode transition hardened | failed release build → generated registrant cleanup regression | debug native test가 남긴 dev-only `IntegrationTestPlugin` registrant를 release 직전에 exact-path로 제거하고 ignored generated file을 source snapshot에서 제외 | final gate |
| 2026-08-23 | P19/P20/P22 | E2E beta checkpoint passed | common gate + package/evidence scripts | docs 71, generated 4, format 325, architecture 226, analyze 0, Flutter 579 + Android native 43 tests; beta ZIP/APK와 source snapshot 일치 | initial commit |
| 2026-08-23 | Scope | Final verification scope narrowed | user decision | 새 checker·harness 확장을 중단하고 Windows flavor/runtime identity와 배포 고지 결함, 기존 gate, 패키징, 실제 왕복만 유지 | focused final run |
| 2026-08-23 | P19/P20 | Windows flavor and distribution defects corrected | focused regressions + `tool/verify.ps1 -Platform All` | native/Dart default를 beta로 정렬하고 runtime identity mismatch를 fail-closed 처리; ZIP에 asset/theme notices 포함; generated 4, format 325, architecture 226, analyze 0, Flutter 582 tests 통과 | final packages |
| 2026-08-23 | P19/P22 | Android API matrix debug E2E passed | dedicated API 31/33 AVDs | API 31·33에서도 actual composition, Drift Todo create/re-read, Calendar와 Back 통과; API 24/31/33/36 debug journey 확보 | package binding |
| 2026-08-23 | P20 | Final packages rebuilt | `package_windows.ps1` + `package_android.ps1` | beta ZIP `9a950f0960ef015029c0ee9e08c6542d9682c1e48179498d75f81ea60b5d184c`, beta APK `311b8dab8e518c55ea93e49cd23da947306b31665e4a228868efda0547d51f8f`, unsigned production portable `9108d2928224b0d688ec6925ce2bda90aa6685277e2e4a2574d8daf37120ddd3` | actual round trip |
| 2026-08-23 | P22 | Actual v1 backup round trip passed | Neutralino UI → final beta ZIP UI → final production ZIP UI | v1 envelope, Preferences, Todo fields/count가 두 재내보내기에서 의미 동일; 세 JSON hash와 pre-import stores를 외부 보존, private Todo title/path는 기록하지 않음 | documentation and commit |
| 2026-08-23 | P19 | Lazy scroll test assumption corrected | failing full gate → focused preferences suite | 화면 밖 sound panel을 즉시 생성됐다고 가정한 3개 test를 실제 scroll/delegate 계약으로 변경; focused 20 tests 통과 | refresh source-bound packages |
| 2026-08-23 | P20/P22 | Source-bound packages refreshed | beta ZIP/APK + unsigned production ZIP | source snapshot `4a649d7734e63717ee39f7f536d834d6e9b248a1481b46106cace041ced230ef`; beta ZIP `e5fc939e60b57ff858721d3d4eba303103f3ee2c9eb935f6425857b7ab432c35`, beta APK `311b8dab8e518c55ea93e49cd23da947306b31665e4a228868efda0547d51f8f`, production ZIP `71e244230510fbb6fda1a2eafbd04e2251f133075c225ca9d09c96f8b4547812` | runtime equivalence and final gate |
| 2026-08-23 | P22 | Rebuilt Windows runtime equivalence confirmed | extracted file and PE section hashes | 두 flavor 모두 25개 중 24개 파일 byte-identical; runner `.text/.data/.pdata/.rsrc/.reloc` 동일, `.rdata` 차이는 debug timestamp 2 bytes만 확인 | final gate |
| 2026-08-23 | P19/P22 | Final verified checkpoint passed | `tool/verify.ps1 -Platform All`; release evidence gates | docs 74, generated 4, format 325, architecture 226, analyze 0, Flutter 582 tests; Beta exit 0, Production exit 1은 세 external matrix와 signed MSIX/production APK/AAB 부재만 보고 | commit |

## Artifacts

| Artifact | Owning item | State | Hash/evidence | Notes |
| -------- | ----------- | ----- | ------------- | ----- |
| `CONTEXT.md` | Domain decisions | Existing | record at P0 | 공통 언어 |
| `docs/adr/0001`–`0023` | Architecture decisions | Existing + P2 addition | ADR 0023 SHA-256 `f730a5f394d36fd5292464dad38b8535024bcb124e4e90932d4440532132c732` | Accepted decisions and local civil DST policy |
| `docs/plans/2026-08-22-clock-rhythm-flutter-port/plan.md` | Plan | Ready | record after Git init | Master entry point |
| `docs/plans/2026-08-22-clock-rhythm-flutter-port/items/P0.md`–`P22.md` | Plan | Ready | record after Git init | Item SSOT |
| `.fvmrc` | P0 | Created | SHA-256 `3976b19c8e208f57aeb42316b54672b1575550899045228d0024b84f71b8e53d` | Flutter 3.44.7 |
| `pubspec.lock` | P0 | Created | SHA-256 `28ee4658b73497151d6f024267b46233ebd38ebc0481bcde5df646af69965326` | pub.dev lock SSOT |
| Flutter source/tests | P0–P18 | Verified locally | `tool/verify.ps1 -Platform All`: 582 tests | generated/docs/format/architecture/analyze 포함 |
| `integration_test/app_e2e_test.dart` | P19/P22 | Verified on Android emulator | SHA-256 `ad1f165b38954657d931de76523031622af9d2ea64dbf2e423a5c71aef9bcd06` | API 24/31/33/36 actual composition, Drift Todo, Calendar, Back; debug evidence only |
| `docs/verification/legacy-behavior-matrix.md` | P1–P22 | Verified | SHA-256 `86909a8d818a4f61b9190802c11908ee3756d87d10cd1ebc8834570756642316` | source 49 files / 182 behaviors; 160 Verified / 22 ADR-backed Dispositioned / 0 Pending |
| `tool/check_architecture.dart` | P1 | Verified | SHA-256 `5b62249dc776b22b937dfb2b62e898307c69d620b0b49cbe69c2932ca7bcdd87` | latest production scan 226 Dart files |
| Rhythm Domain/Application source and tests | P2 | Verified | aggregate SHA-256 `43068ba189c149d89f11831efa7a8e24e8c581d1df0b8afc21ef03bc93858a3f` across 28 files | focused 65 tests; full suite 112 tests |
| `build/windows/x64/runner/Debug/clock_rhythm.exe` | P0 | Verified | SHA-256 `23031c8803c15cd9dbaa6002cd0af81ca953619208df3ff34ed424c3c55829a5` | debug evidence, ignored build output |
| `build/app/outputs/flutter-apk/app-debug.apk` | P0 | Verified | SHA-256 `79aa4360a157b706e76a805bea56201d97601743dc6d3b212cdccf85c657b44a` | API 24/36 runtime evidence, ignored build output |
| CI/build/package scripts | P19–P20 | Verified locally | 16 PowerShell scripts parse; source/artifact binding, E2E-to-release cleanup, negative probes and both beta packages pass | workflows are pinned but no remote CI run exists |
| `artifacts/manifest.json` | P20/P22 | Verified local ignored artifact | source snapshot SHA-256 `4a649d7734e63717ee39f7f536d834d6e9b248a1481b46106cace041ced230ef` | beta ZIP/APK와 unsigned production portable을 같은 source snapshot에 연결 |
| `artifacts/windows/clock-rhythm-beta-0.1.0+1-windows-x64.zip` | P20 | Verified local ignored artifact | SHA-256 `e5fc939e60b57ff858721d3d4eba303103f3ee2c9eb935f6425857b7ab432c35` | notices 포함 portable ZIP, unsigned as documented |
| `artifacts/windows/clock-rhythm-production-1.0.0+1-windows-x64.zip` | P20/P22 | Verified local ignored artifact | SHA-256 `71e244230510fbb6fda1a2eafbd04e2251f133075c225ca9d09c96f8b4547812` | unsigned data-compatibility evidence; production-signed artifact 아님 |
| `artifacts/android/clock-rhythm-beta-0.1.0+1.apk` | P20 | Verified local ignored artifact | SHA-256 `311b8dab8e518c55ea93e49cd23da947306b31665e4a228868efda0547d51f8f` | `dev.wndls.clockrhythm.beta`, development signed |
| Portable Backup round trip | P22 | Verified outside repository | JSON SHA-256 `281ea7b5c30f344fc73882b4c267d32e3dc95066590680325aa229abc92dcf19`, `99dfc86d3b5d9117c1e54c3bc045fca6ce19d08e3158dd354f1f30cc5ec0bac4`, `8d77e514a4211399f892c6b011660a8173ee6443313d91593281eaeef547e7e4` | Neutralino → beta → production 의미 동일; 상세는 `docs/verification/backup-roundtrip.md` |
| Release evidence | P22 | Beta qualified / production incomplete | Beta exit 0; Production exit 1 with Windows/Android/installed-update matrices and missing signed MSIX/production APK/AAB only | physical/install/signing/accessibility evidence remains Pending |

## Cancellation / resume state

- Cancellation requested: No
- Safe stop point: source-bound final packages and actual v1 backup round-trip checkpoint
- In-flight command/process: None
- Uncommitted implementation changes: Windows flavor/runtime identity, distribution notices, focused regressions, final evidence documentation.
- Ignored local artifacts: verified beta ZIP/APK, unsigned production portable ZIP, external round-trip evidence, `build/`, Gradle/FVM/Dart caches와 generated staging은 source/Git 추적 대상이 아닙니다.
- Resume checklist:
  1. 최신 사용자 지시가 이 plan을 변경했는지 확인합니다.
  2. master dependency와 active P-item dependency가 완료됐는지 확인합니다.
  3. target/source `git status`와 source commit SHA를 기록합니다.
  4. active item의 마지막 observable event와 artifact를 확인합니다.
  5. 해당 item의 failing probe부터 재개하고 통과한 단계를 불필요하게 반복하지 않습니다.

## User intervention requests

| Request | Required by | State | What the user must decide/do | Resume condition |
| ------- | ----------- | ----- | ---------------------------- | ---------------- |
| Flutter/Windows/Android toolchain 설치 및 Android license 수락 | P0 | Resolved | 사용자가 [Google Android SDK License Agreement](https://developer.android.com/studio/terms)를 명시적으로 수락했고 도구체인을 설치함 | `sdkmanager --licenses`와 `fvm flutter doctor -v` green |
| Windows 10 및 clean-user 설치 환경 | P22 | External evidence required | physical/VM 환경과 실행 권한 제공 | Windows 10과 clean-user install/update evidence 기록 가능 |
| Android physical device | P22 | External evidence required | API/제조사 정보와 reboot/Doze/time change 검증 가능한 장치 제공 | physical matrix 수행 가능 |
| Production Windows/Android signing material | P20/P22 | Needs user | source 밖의 certificate/keystore/password 경로 제공 | signed MSIX/AAB 생성 가능 |

## Ledger update contract

- P-item 시작 시 해당 item 파일과 위 table 상태를 `In Progress`로 바꾸고 owner/start time을 기록합니다.
- command를 실행할 때 전체 민감 출력 대신 command, exit code, 핵심 결과, report/artifact 경로를 events에 기록합니다.
- artifact가 바뀌면 path, hash 또는 CI run/evidence reference를 Artifacts에 기록합니다.
- blocker는 같은 실패를 숨기지 말고 user intervention table과 active item Risk/Notes에 연결합니다.
- 완료 시 item의 Completion criteria와 TDD/Validation을 모두 확인하고 `Done`으로 바꿉니다. 다음 dependency가 충족된 item만 시작합니다.
- 중단 시 in-flight process, working tree, 마지막 passing command, 다음 failing probe를 Cancellation / resume state에 남깁니다.
