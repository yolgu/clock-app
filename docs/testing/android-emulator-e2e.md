# Android emulator E2E

이 검증은 실제 Android composition root, platform channel, Drift database와 Flutter UI를 한 프로세스에서 연결해 핵심 사용자 여정을 확인합니다. 전용 emulator의 beta data를 비운 뒤 실행하며 production 또는 사용 중인 개인 data에는 사용하지 않습니다.

## Covered journey

`integration_test/app_e2e_test.dart`는 다음 흐름을 실행합니다.

1. beta 앱을 실제 runtime composition으로 시작합니다.
2. Clock 화면에서 Todo를 만들고 저장소 재조회 결과를 확인합니다.
3. Calendar에서 같은 Todo를 확인합니다.
4. Android Back으로 Clock에 돌아가 같은 Todo가 유지되는지 확인합니다.

파일 선택기, notification/exact-alarm permission dialog, process death, reboot, Doze와 installed update는 이 deterministic Flutter E2E의 범위가 아닙니다. 해당 동작은 [Android lifecycle checklist](android-lifecycle-checklist.md)와 artifact-bound 수동 evidence를 사용합니다.

## Run on a dedicated emulator

저장소 루트에서 AVD를 시작합니다.

```powershell
fvm flutter emulators --launch clock_rhythm_api36
adb devices -l
```

표시된 emulator serial을 사용해 beta 앱과 test package의 기존 data를 제거합니다. 이 단계는 전용 E2E emulator에서만 수행합니다.

```powershell
adb -s <emulator-serial> uninstall dev.wndls.clockrhythm.beta
adb -s <emulator-serial> uninstall dev.wndls.clockrhythm.beta.test
```

package가 아직 없다는 응답은 clean-state 조건을 이미 만족한다는 뜻입니다. 이어서 실제 E2E를 실행합니다.

```powershell
fvm flutter test integration_test/app_e2e_test.dart `
  -d <emulator-serial> `
  --flavor beta `
  --dart-define=CLOCK_RHYTHM_FLAVOR=beta
```

완료 기록에는 AVD 이름, API, model, build fingerprint, source revision 또는 source snapshot, 명령, 날짜와 결과를 남깁니다. 이 테스트가 통과해도 permission/lifecycle/install matrix cell을 자동으로 Passed로 바꾸지 않습니다.

## 2026-08-23 execution record

| Field | API 36 final run | API 24 compatibility run |
| --- | --- | --- |
| AVD | `clock_rhythm_api36` | `clock_rhythm_api24` |
| Model | `sdk_gphone64_x86_64` | `Android SDK built for x86_64` |
| Build fingerprint | `google/sdk_gphone64_x86_64/emu64xa:16/BE2A.250530.026.F3/13894323:userdebug/dev-keys` | `Android/sdk_google_phone_x86_64/generic_x86_64:7.0/NYC/6696031:userdebug/dev-keys` |
| Source snapshot | `1cea44f26ce5cfb68e51ae2b18d2b9ae555f09fc78d84a0b64e72adde5487f42` | `b2c3a02ea6191dd5ffc5cf0de0f666d66a134c89e92da624b728abe338cf0604` |
| E2E test SHA-256 | `ad1f165b38954657d931de76523031622af9d2ea64dbf2e423a5c71aef9bcd06` | `ad1f165b38954657d931de76523031622af9d2ea64dbf2e423a5c71aef9bcd06` |
| Debug APK SHA-256 | `21061dae35370275234a37482f22719e2c203ec610067aa843587fdfdf37dc0e` | `7816651f3e51ff4d7ea0e206b865d0dfca7e97ca5e7a4496ff231d8a33f40bed` |
| Result | Passed | Passed |

API 36에서는 안정화된 test를 clean state에서 연속 두 번 통과시킨 뒤, final source snapshot으로 한 번 더 통과했습니다. API 24에서도 같은 E2E test SHA가 통과했습니다. Debug APK는 실행별 재빌드 산출물이므로 release matrix artifact로 재사용하지 않습니다.
