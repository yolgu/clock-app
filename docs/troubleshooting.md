# Troubleshooting

먼저 실패한 명령의 첫 오류와 exit code를 보존합니다. 같은 명령을 반복하기 전에 도구체인, 입력 파일, platform permission, signing credential 중 어느 경계에서 실패했는지 분류합니다. 개인 데이터나 secret이 포함된 원문 log는 issue나 release evidence에 첨부하지 않습니다.

## FVM 또는 Flutter를 찾지 못함

증상:

- `FVM is not available on the process, user, or machine PATH.`
- active Flutter가 3.44.7이 아님

확인:

```powershell
fvm --version
fvm flutter --version
Get-Content .fvmrc
```

FVM을 PATH에 추가한 뒤 terminal을 다시 열거나 현재 process에 실행 파일을 명시합니다.

```powershell
$env:CLOCK_RHYTHM_FVM = '<absolute-path-to-fvm-executable>'
powershell -ExecutionPolicy Bypass -File tool/preflight.ps1 -Platform Core
```

`.fvmrc`를 다른 Flutter version으로 바꾸거나 system `flutter`로 gate를 우회하지 않습니다.

## `flutter doctor`의 Windows 오류

`Visual Studio - develop Windows apps`가 없거나 오류인 경우 Visual Studio Installer에서 **Desktop development with C++** workload와 Windows SDK를 설치·수정합니다. Visual Studio Code만 설치한 상태로는 native Windows runner를 build할 수 없습니다.

```powershell
fvm flutter doctor -v
powershell -ExecutionPolicy Bypass -File tool/preflight.ps1 -Platform Windows
```

Windows 10 build 17763보다 오래된 OS, Windows Arm64, macOS/Linux host의 Windows release build는 현재 지원 계약이 아닙니다.

## Android SDK 또는 license 오류

preflight는 SDK Platform 36과 Build-Tools 36.0.0을 찾습니다. SDK가 비표준 위치에 있으면 올바른 root를 지정합니다.

```powershell
$env:ANDROID_HOME = '<absolute-android-sdk-root>'
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
sdkmanager --licenses
fvm flutter doctor -v
```

License 내용은 사용자가 직접 검토하고 승인합니다. 저장소 script가 non-interactive로 대신 승인하도록 수정하지 않습니다. JDK/Gradle 오류는 CI 기준 Java 25와 [`android/settings.gradle.kts`](../android/settings.gradle.kts), Gradle wrapper를 대조하고 임의로 wrapper를 downgrade하지 않습니다.

## locked dependency 또는 generated file 오류

```powershell
fvm flutter pub get --enforce-lockfile
powershell -ExecutionPolicy Bypass -File tool/generate.ps1 -Platform Core
powershell -ExecutionPolicy Bypass -File tool/check_generated.ps1 -Platform Core
```

`--enforce-lockfile`이 실패하면 `pubspec.lock`이 없는지, [`pubspec.yaml`](../pubspec.yaml)과 lockfile이 함께 의도적으로 변경됐는지 확인합니다. Drift의 `*.g.dart`와 `lib/l10n/generated/`를 직접 고치지 않습니다.

## Windows 창이 닫혔지만 process가 남아 있음

정상 계약입니다. Windows의 close button은 창을 tray로 숨기고 Rhythm delivery를 유지합니다. tray의 **Open**으로 다시 열고, process를 완전히 종료하려면 tray의 **Quit**을 사용합니다. Quit은 예약 delivery와 재생 중인 event sound를 중단합니다.

두 번째 interactive launch는 기존 창을 표시·focus해야 하고, `--hidden` 자동 시작 launch는 기존 창을 띄우지 않고 종료해야 합니다. 다르게 동작하면 [플랫폼 checklist](verification/platform-checklist.md)의 single-instance 행과 다음 harness를 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_windows_lifecycle.ps1
```

## Windows 자동 시작이 저장됐지만 동작하지 않음

Preferences의 체크 값은 desired state입니다. Unpackaged ZIP은 flavor 전용 HKCU Run registration에 quoted executable과 `--hidden`을 사용하고, packaged MSIX는 StartupTask 상태를 따릅니다. Windows가 사용자 승인을 요구하거나 registration reconciliation이 실패하면 Preferences에 repair action이 표시될 수 있습니다.

- beta와 production의 registration name이 서로 다른지 확인합니다.
- 이전 Neutralino registration을 Clock Rhythm이 자동 삭제할 것이라고 기대하지 않습니다.
- 자동 시작으로 열린 앱은 hidden Idle입니다. Start가 자동 실행되지 않는 것이 정상입니다.
- packaged StartupTask가 사용자에 의해 disabled된 경우 Windows 설정에서 상태를 확인한 뒤 repair를 다시 실행합니다.

## Android에서 Start가 거부됨

Android는 명시적 Start 시 notification permission과 exact-alarm capability를 확인합니다.

- API 33 이상: notification permission을 확인합니다.
- API 31 이상: **Alarms & reminders** special access를 확인합니다.
- API 24–30: exact-alarm access는 platform policy상 granted로 취급하지만 notification/channel 설정은 여전히 delivery를 막을 수 있습니다.

Permission을 나중에 허용해도 session이 자동으로 Start되지 않습니다. 앱으로 돌아와 상태를 확인하고 사용자가 다시 Start합니다. Permission을 revoke하거나 force-stop한 뒤에는 silent recovery 대신 설명과 명시적 recovery/Start가 필요합니다.

## Android 알림이 늦거나 경계를 건너뜀

Android는 foreground service나 permanent notification을 사용하지 않고 `setExactAndAllowWhileIdle` 기반 delivery를 사용합니다. Focus/Rest가 9분보다 짧으면 deep idle에서 운영체제가 delivery를 늦출 수 있습니다. 늦은 과거 경계는 한꺼번에 replay하지 않고 첫 strictly future boundary로 이동합니다.

다음 조건은 emulator unit test만으로 production 자격을 증명하지 못합니다.

- 제조사 battery policy
- Doze 진입과 해제
- process 제거와 force-stop
- reboot, app update, wall-clock/time-zone 변경
- 실제 notification/exact-alarm permission 화면

해당 문제는 [Android lifecycle checklist](testing/android-lifecycle-checklist.md)의 device/API/build/package 정보와 함께 재현합니다. Battery optimization exemption이나 full-screen intent를 해결책으로 추가하지 않습니다.

## Portable Backup import가 거부됨

다음을 확인합니다.

- UTF-8 JSON이며 32 MiB 이하인지
- `appName`이 정확히 `Clock Rhythm`인지
- `schemaVersion`이 integer `1`인지
- Preferences와 `todos`가 모두 있는지
- Todo가 25,000개 이하이고 각 ID가 unique인지
- title/date/time/completion/timestamp/display order가 유효한지

Unknown additive field는 허용하지만 unknown schema version을 추측하거나 낮춰 읽지 않습니다. Invalid Todo를 파일에서 임의로 삭제해 부분 import하지 말고 원본 앱에서 데이터를 고친 뒤 새 v1 backup을 export합니다. 오류 보고에는 Todo title이나 backup 원문을 첨부하지 않습니다.

Import preview에서 Cancel하면 아무것도 바뀌지 않습니다. Confirm 뒤 replacement가 실패하면 durable Preferences/Todo는 이전 상태이지만 현재 설치의 Rhythm Session은 안전을 위해 Idle입니다.

## Custom Notification Sound 문제

Windows는 확장자가 MP3이고 20 MiB 이하인 한 파일만 받습니다. 구조 검사와 decoder 준비를 통과한 뒤 flavor별 private storage로 복사하므로 원본 파일을 이동해도 재생돼야 합니다.

- 선택 실패: extension, 크기와 실제 MP3 구조를 확인합니다.
- import 후 default sound: 정상입니다. Custom Notification Sound는 Portable Backup에 없으므로 다시 선택합니다.
- playback 실패: bundled sound fallback과 Preferences repair 상태를 확인합니다.
- Mute: 소리만 억제하고 visible notification은 계속 표시됩니다.
- volume 0%: Mute와 다르며 notification은 표시되고 경고만 나타납니다.

Android 첫 release는 bundled default 또는 Mute만 지원하며 Custom Notification Sound와 app volume은 지원하지 않습니다.

## Database recovery 화면이 나타남

Database location, newer unsupported schema, integrity, migration 또는 stored-data 검증 실패 시 원본을 빈 database로 덮어쓰지 않고 recovery 화면이 나타납니다.

1. 일시적 잠금 가능성이 있으면 **Retry**를 먼저 사용합니다.
2. 검증된 Portable Backup이 있으면 **Import Portable Backup**을 사용합니다.
3. **Reset**은 마지막 수단이며 이중 확인 후 기존 database files를 recovery directory로 보존합니다.

Recovery archive를 이전 version database로 덮어쓰거나 reverse migration에 사용하지 않습니다. 실패가 반복되면 archive와 앱 version/hash는 보존하되 전체 private path와 개인 record는 redacted하여 기록합니다.

## Production signing 또는 packaging 실패

Production 명령은 외부 certificate/keystore/password가 없으면 실패해야 합니다. `-UnsignedStaging` output은 구조 검사 전용이며 release로 배포하거나 “signed”로 표기할 수 없습니다. Debug key나 빈 password로 production artifact를 가장하지 않습니다.

정확한 environment 변수와 artifact 검사 명령은 [release 절차](release/release-process.md)를 따릅니다. Store enrollment·submission과 signing key 생성·보관은 이 저장소가 수행하지 않습니다.
