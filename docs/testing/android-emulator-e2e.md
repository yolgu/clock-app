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

| API | AVD | Model | Build fingerprint | Source snapshot | Debug APK SHA-256 | Result |
| --- | --- | --- | --- | --- | --- | --- |
| 24 | `clock_rhythm_api24` | `Android SDK built for x86_64` | `Android/sdk_google_phone_x86_64/generic_x86_64:7.0/NYC/6696031:userdebug/dev-keys` | `b2c3a02ea6191dd5ffc5cf0de0f666d66a134c89e92da624b728abe338cf0604` | `7816651f3e51ff4d7ea0e206b865d0dfca7e97ca5e7a4496ff231d8a33f40bed` | Passed |
| 31 | `clock_rhythm_api31` | `sdk_gphone64_x86_64` | `google/sdk_gphone64_x86_64/emulator64_x86_64_arm64:12/SE1A.220826.008/10564458:userdebug/dev-keys` | Not separately recorded; debug-only run | `b6668ae49196764b5bef10b03f8d81600a9c5e3fee7a2384d0188f304f14de77` | Passed |
| 33 | `clock_rhythm_api33` | `sdk_gphone64_x86_64` | `google/sdk_gphone64_x86_64/emu64x:13/TE1A.240213.009/12342917:userdebug/dev-keys` | Not separately recorded; debug-only run | `b9599b838500e29b272b922fa9a25d399e727e4e4538cce7fe9337c061886650` | Passed |
| 36 | `clock_rhythm_api36` | `sdk_gphone64_x86_64` | `google/sdk_gphone64_x86_64/emu64xa:16/BE2A.250530.026.F3/13894323:userdebug/dev-keys` | `1cea44f26ce5cfb68e51ae2b18d2b9ae555f09fc78d84a0b64e72adde5487f42` | `21061dae35370275234a37482f22719e2c203ec610067aa843587fdfdf37dc0e` | Passed |

Every run used E2E test SHA-256 `ad1f165b38954657d931de76523031622af9d2ea64dbf2e423a5c71aef9bcd06`. API 36 passed twice in succession from clean state before the final recorded run; API 24, 31, and 33 passed the same journey from clean state once. API 31 and 33 did not record a source snapshot at execution time, so this document does not retroactively assign the later release snapshot to them. Debug APKs are rebuilt per run and are not release-matrix artifacts.
