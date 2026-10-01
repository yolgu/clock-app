# Toss-inspired refactor verification

## Source and targets

- Design-token source: `https://www.tossinvest.com/?focusedProductCode=A000660`
- App source: Clock Rhythm Flutter workspace on branch `main`
- Flutter: 3.44.7 stable
- Dart: 3.12.2
- Windows target: Windows 11 25H2, beta release, x64
- Android target: beta release APK, API 24+ contract

## Automated verification

| Command | Result |
| --- | --- |
| `powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform Core` | Exit 0. Documentation, generated output, Dart formatting, 228-file architecture check, static analysis, and 601 Flutter tests passed. |
| `powershell -ExecutionPolicy Bypass -File tool/build_windows.ps1 -Flavor Beta` | Exit 0. Windows release build, native autostart contract, duplicate-launch behavior, hide/reopen lifecycle, and exact cleanup passed. |
| `powershell -ExecutionPolicy Bypass -File tool/build_android.ps1 -Flavor Beta -Artifact Apk` | Exit 0. Beta and production debug Android Rhythm unit suites each reported 43 passed and 0 failed; beta release APK built. |

## Artifacts

- Windows bundle: `build/windows/x64/runner/Release`
- Windows executable SHA-256: `717DB6EEC73C00C25588D319D13D87AB91D90ACC88E1E15AABA6B5FAB9C59E2D`
- Android APK: `build/app/outputs/flutter-apk/app-beta-release.apk`
- Android APK size at verification: 64,460,885 bytes
- Android APK SHA-256: `2720B9EEE9A71B68E63AF82D9ED3036CE5B5742AF07AB0F65F49C80CDDE7E8F7`
- Golden baselines:
  - `test/goldens/baselines/compact_calendar_ko_200.png`
  - `test/goldens/baselines/wide_calendar_en_neon_dusk.png`
  - `test/goldens/baselines/windows_clock_en_current.png`
  - `test/goldens/baselines/android_theme_ko_current.png`

## Warnings and limits

- Locked dependencies report newer incompatible versions; no dependency was upgraded.
- Android Gradle reports existing AGP 9/Kotlin deprecation warnings and an SDK XML version warning. They did not fail unit tests or the release build.
- No Android emulator or physical device was connected. Android rendering remains proven by widget/golden coverage and APK compilation, not by a real Android device capture.
