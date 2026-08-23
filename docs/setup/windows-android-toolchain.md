# Windows·Android 도구체인 설정

이 문서는 Clock Rhythm을 clean checkout에서 생성·검증·build하기 위한 개발 환경 계약입니다. 저장소 스크립트는 이미 설치된 도구를 검사하고 실행할 뿐, Flutter·Visual Studio·Android SDK를 설치하거나 license를 대신 승인하지 않습니다.

## 기준 버전과 소유 위치

| 항목 | 저장소 계약 | 확인 위치 |
| --- | --- | --- |
| Flutter | `3.44.7` | [`.fvmrc`](../../.fvmrc) |
| Dart | Flutter 3.44.7에 포함된 SDK | `fvm dart --version` |
| dependency | 잠긴 package graph | [`pubspec.lock`](../../pubspec.lock) |
| Android | min API 24, compile/target API 36 | [`android/app/build.gradle.kts`](../../android/app/build.gradle.kts) |
| Android Build Tools | `36.0.0` preflight 요구 | [`tool/preflight.ps1`](../../tool/preflight.ps1) |
| Windows | Windows 10/11 x64 | [`windows/runner/CMakeLists.txt`](../../windows/runner/CMakeLists.txt) |
| CI Java | Temurin 25 | [Android workflow](../../.github/workflows/android.yml) |

Flutter와 FVM은 전역 Flutter 설치 후 프로젝트별 SDK를 FVM으로 선택하는 방식을 사용합니다. 설치 방법은 [Flutter 설치 안내](https://docs.flutter.dev/install)와 [FVM 설치 안내](https://fvm.app/documentation/getting-started/installation)를 따릅니다. SDK cache와 production signing material은 저장소에 넣지 않습니다.

## 1. 공통 도구 준비

다음을 사용자가 직접 설치합니다.

- Git
- PowerShell 7 권장(`pwsh`); Windows PowerShell에서도 저장소의 `.ps1` 명령을 실행할 수 있어야 합니다.
- Flutter SDK와 PATH에서 실행 가능한 FVM
- Windows와 Android build를 모두 할 경우 각 플랫폼 도구체인

저장소를 checkout한 다음 루트에서 pinned SDK를 준비합니다.

```powershell
fvm install 3.44.7
fvm use 3.44.7 --force --skip-pub-get
fvm flutter --version
```

마지막 명령의 첫 줄에 `Flutter 3.44.7`이 보여야 합니다. FVM이 사용자·machine PATH에는 있지만 현재 shell에서만 보이지 않는 경우, 새 terminal을 열거나 이 세션에만 실행 파일을 지정합니다.

```powershell
$env:CLOCK_RHYTHM_FVM = '<absolute-path-to-fvm-executable>'
```

이 값은 비밀이 아니지만 machine-specific path이므로 source control에 기록하지 않습니다.

## 2. Windows build 환경

[Flutter Windows 설정 안내](https://docs.flutter.dev/platform-integration/windows/setup)에 따라 Visual Studio를 설치하고 **Desktop development with C++** workload를 선택합니다. Visual Studio Code가 아니라 C++ compiler와 Windows SDK를 제공하는 Visual Studio가 필요합니다.

설치 후 확인합니다.

```powershell
fvm flutter doctor -v
fvm flutter devices
powershell -ExecutionPolicy Bypass -File tool/preflight.ps1 -Platform Windows
```

기대 결과는 다음과 같습니다.

- `flutter doctor -v`에서 `Visual Studio - develop Windows apps`가 오류 없이 표시됩니다.
- `flutter devices`에 `windows` device가 표시됩니다.
- preflight 마지막에 `Flutter 3.44.7 are ready for Windows verification.`을 포함한 성공 메시지가 표시됩니다.

Windows runner는 C++17과 Windows SDK를 사용하며 Windows 10 build 17763 이전에서는 실행을 거부합니다. 실제 지원 판정은 Windows 10과 11 x64 양쪽의 [플랫폼 checklist](../verification/platform-checklist.md) 증거가 필요합니다.

## 3. Android build 환경

Android Studio와 SDK Manager를 설치하고 다음 구성 요소를 준비합니다.

- Android SDK Platform 36
- Android SDK Build-Tools 36.0.0
- 최신 안정 Android SDK Platform-Tools
- Android SDK Command-line Tools
- 검증할 API 24, 31, 33, 36 emulator image
- Gradle이 사용할 JDK; CI 기준은 Temurin 25이며 local에서는 `flutter doctor -v`와 Gradle gate가 선택한 JDK로 통과해야 합니다.

Android Studio SDK Manager를 사용하거나, SDK 경로가 이미 올바르게 설정된 환경에서 다음과 같이 설치할 수 있습니다.

```powershell
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
```

Android SDK license 검토와 승인은 사용자 책임입니다. 내용을 확인한 뒤 Android Studio의 안내를 따르거나 다음 대화형 명령을 직접 실행합니다.

```powershell
sdkmanager --licenses
```

저장소 script나 CI를 license 자동 승인 수단으로 바꾸지 않습니다. 설치 후 확인합니다.

```powershell
fvm flutter doctor -v
fvm flutter devices
powershell -ExecutionPolicy Bypass -File tool/preflight.ps1 -Platform Android
```

기대 결과는 Android toolchain에 오류가 없고 preflight가 SDK의 `platforms/android-36`과 `build-tools/36.0.0`을 확인한 뒤 성공하는 것입니다. SDK가 표준 위치에 없으면 `ANDROID_HOME` 또는 `ANDROID_SDK_ROOT` 중 하나를 해당 SDK root로 설정합니다.

## 4. dependency와 생성물

lockfile을 바꾸지 않고 dependency를 해석하고 생성물을 갱신합니다.

```powershell
fvm flutter pub get --enforce-lockfile
powershell -ExecutionPolicy Bypass -File tool/generate.ps1 -Platform Core
powershell -ExecutionPolicy Bypass -File tool/check_generated.ps1 -Platform Core
```

`tool/generate.ps1`은 Flutter localization과 Drift/build_runner output을 생성합니다. `lib/l10n/generated/` 또는 `*.g.dart`를 직접 편집하지 않습니다. `--enforce-lockfile` 실패 시 임의로 dependency를 upgrade하지 말고 [`pubspec.yaml`](../../pubspec.yaml)과 `pubspec.lock`의 변경 의도를 별도 검토합니다.

## 5. local 실행

beta와 production이 같은 native identity를 사용하지 않도록 flavor를 항상 명시합니다.

Windows beta:

```powershell
$env:CLOCK_RHYTHM_WINDOWS_FLAVOR = 'beta'
fvm flutter run -d windows --dart-define=CLOCK_RHYTHM_FLAVOR=beta
Remove-Item Env:\CLOCK_RHYTHM_WINDOWS_FLAVOR
```

Android beta:

```powershell
fvm flutter run -d '<android-device-id>' --flavor beta --dart-define=CLOCK_RHYTHM_FLAVOR=beta
```

배포 build에는 직접 `flutter build`를 조합하지 말고 [release 절차](../release/release-process.md)의 저장소 wrapper를 사용합니다. wrapper가 Dart flavor, native package identity, version, signing 경계를 한 번에 검사합니다.

## 6. 첫 검증

플랫폼 하나만 준비됐다면 해당 값으로, 둘 다 준비됐다면 `All`로 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/check_docs.ps1
powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform All
```

`verify.ps1`은 preflight, locked dependency와 생성물 일치, format, architecture, analyzer, 전체 Dart/Flutter test를 순서대로 실행하며 첫 실패를 그대로 반환합니다. 플랫폼 build와 수동 증거는 별도로 [플랫폼 checklist](../verification/platform-checklist.md)를 완료해야 합니다.

설정 문제가 생기면 [troubleshooting](../troubleshooting.md)의 도구체인 항목부터 확인합니다.
