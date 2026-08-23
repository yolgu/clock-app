# CI와 로컬 품질 게이트

Clock Rhythm은 `.fvmrc`의 Flutter 3.44.7과 `pubspec.lock`을 로컬·CI의 공통 도구체인 계약으로 사용합니다. GitHub workflow는 저장소에만 정의되어 있으며 remote 생성, push, branch protection, signing secret 저장 또는 store upload를 수행하지 않습니다.

## 로컬 명령

- 전체 워크스테이션: `powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform All`
- Windows 전용 환경: `powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform Windows`
- Android 전용 환경: `powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform Android`
- 생성물 갱신: `powershell -ExecutionPolicy Bypass -File tool/generate.ps1`
- 생성물 일치 검사: `powershell -ExecutionPolicy Bypass -File tool/check_generated.ps1`
- Windows beta raw build gate: `powershell -ExecutionPolicy Bypass -File tool/build_windows.ps1 -Flavor Beta`
- Android beta raw APK gate: `powershell -ExecutionPolicy Bypass -File tool/build_android.ps1 -Flavor Beta -Artifact Apk`
- Verified Windows beta ZIP: `powershell -ExecutionPolicy Bypass -File tool/package_windows.ps1 -Flavor Beta -Artifact Zip`
- Verified Android beta APK: `powershell -ExecutionPolicy Bypass -File tool/package_android.ps1 -Flavor Beta -Artifact Apk`

`verify.ps1`은 기존 생성물 hash snapshot을 먼저 잡은 뒤 잠긴 dependency를 해석하고, `gen_l10n`/build_runner 생성과 snapshot 비교, format, architecture 검사, analyze, 전체 Dart/Flutter test 순서로 실행하며 첫 실패의 nonzero exit code를 그대로 반환합니다. 따라서 `pub get`이 localization 생성을 유발해도 stale 입력을 숨기지 않으며, 첫 Git commit 전의 untracked 생성물도 검사합니다.

## CI 계약

`windows.yml`과 `android.yml`은 검토한 action commit SHA만 직접 참조합니다. cache key는 runner platform, Flutter 3.44.7, `pubspec.lock` hash를 포함합니다. Windows job은 공통 검증 뒤 검사된 Windows beta ZIP을 만들고, Android job은 Java/Kotlin tests를 포함한 공통 검증 뒤 개발 키로 서명되고 검사된 beta APK를 만듭니다. production MSIX/AAB는 외부 signing material이 있는 release-owner 환경에서만 패키징하며 일반 CI가 unsigned artifact를 production으로 위장하지 않습니다.

## Signing 경계

Beta gate는 production credential을 요구하지 않습니다. Production build 요청은 필요한 credential이 없으면 즉시 실패합니다. `-UnsignedStaging`은 artifact 구조를 검사하기 위한 명시적 staging 옵션일 뿐이며, 출력에 경고를 남기고 release artifact로 간주하지 않습니다. 실제 Windows/MSIX와 Android keystore signing·flavor identity는 P20 packaging gate가 소유합니다.
