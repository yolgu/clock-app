# Release process

이 문서는 Clock Rhythm source에서 검증 가능한 beta/production artifact를 만드는 release-owner 계약입니다. Package script가 성공했다는 사실과 production-ready 판정은 다릅니다. `1.0.0+1`은 [플랫폼 checklist](../verification/platform-checklist.md)의 Windows 10/11, Android physical device, 실제 Neutralino v1 왕복과 installed-update 증거가 모두 통과한 뒤에만 release할 수 있습니다.

Store enrollment·submission, signing key 또는 certificate 생성·보관, Git remote 생성·push와 branch protection 설정은 이 저장소가 수행하지 않습니다.

## 1. 입력과 책임

Release owner는 다음을 준비합니다.

- clean source revision과 그 SHA 또는 source snapshot hash
- [도구체인 설정](../setup/windows-android-toolchain.md)을 통과한 Windows/Android 환경
- production일 경우 저장소 밖의 Windows certificate와 Android keystore
- artifact와 수동 evidence를 보관할 접근 제한 위치
- 실제 Windows 10/11 x64와 Android emulator/physical-device test 환경

Repository는 다음을 소유합니다.

- Flutter 3.44.7과 locked dependency
- beta/production identity, version과 artifact naming
- build, package, artifact inspection과 evidence completeness script
- signing credential이 없을 때 production packaging을 거부하는 경계

실제 credential 값은 source, command history, CI log, artifact manifest 또는 문서에 쓰지 않습니다. 변수 이름과 harmless placeholder는 [`tool/signing.env.example.ps1`](../../tool/signing.env.example.ps1)에서 확인합니다.

## 2. Source gate

Package 전에 같은 source tree에서 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/check_docs.ps1
powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform All
```

한 플랫폼 runner에서만 build할 때는 해당 `-Platform` 값을 사용할 수 있지만, release decision에는 두 플랫폼 결과가 모두 필요합니다. 실패한 gate를 `-SkipPreflight`, unsigned output 또는 수동 파일 복사로 우회하지 않습니다.

`tool/build_windows.ps1`과 `tool/build_android.ps1`은 CI의 raw release-build gate입니다. `build/` 아래 결과는 package manifest와 최종 inspection을 거치지 않았으므로 배포 artifact가 아닙니다.

## 3. Beta package

Beta identity와 version은 다음과 같습니다.

| Platform | Identity | Version | Distribution artifact |
| --- | --- | --- | --- |
| Windows | `dev.wndls.clockrhythm.beta` | `0.1.0+1` | portable x64 ZIP |
| Android | `dev.wndls.clockrhythm.beta` | `0.1.0+1` | development/beta-signed APK |

```powershell
powershell -ExecutionPolicy Bypass -File tool/package_windows.ps1 -Flavor Beta -Artifact Zip
powershell -ExecutionPolicy Bypass -File tool/package_android.ps1 -Flavor Beta -Artifact Apk
```

기본 output은 다음과 같습니다.

- `artifacts/windows/clock-rhythm-beta-0.1.0+1-windows-x64.zip`
- `artifacts/android/clock-rhythm-beta-0.1.0+1.apk`
- `artifacts/manifest.json`
- `artifacts/SHA256SUMS.txt`

Beta MSIX와 beta App Bundle은 계약에 없으며 package script가 거부합니다. Beta APK는 production secret 없이 development signing으로 검사되지만 “production signed”로 표시할 수 없습니다. Portable ZIP은 archive signature를 제공하지 않으므로 hash와 manifest, clean-machine 실행 증거를 함께 보관합니다.

Package script는 platform unit/native test와 release build를 수행하고, staging artifact를 검사한 뒤 최종 위치로 복사해 manifest와 checksum을 갱신합니다. 다음 completeness check는 이미 준비된 P22 evidence를 확인하며, 누락 evidence가 있으면 beta package 자체가 생성됐더라도 nonzero로 끝날 수 있습니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/check_release_evidence.ps1 -ReleaseTier Beta
```

## 4. Production signing 환경

Production Android APK/AAB에는 다음 environment variable이 모두 필요합니다.

- `CLOCK_RHYTHM_ANDROID_KEYSTORE`
- `CLOCK_RHYTHM_ANDROID_KEY_ALIAS`
- `CLOCK_RHYTHM_ANDROID_STORE_PASSWORD`
- `CLOCK_RHYTHM_ANDROID_KEY_PASSWORD`

Production MSIX에는 다음 값이 필요합니다.

- `CLOCK_RHYTHM_WINDOWS_CERTIFICATE`
- `CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD`

Keystore와 certificate path는 repository 밖의 existing file을 가리켜야 합니다. Credential은 격리된 release process의 environment에 직접 주입하고 작업 종료 후 제거합니다. `tool/signing.env.example.ps1`에 실제 값을 기록하거나 실제 credential file을 repository에 둔 채 dot-source하지 않습니다.

Credential 누락, repository 내부 credential path, certificate/keystore 불일치 또는 invalid signature는 명시적 실패입니다. Debug key, 빈 password, self-generated 임시 key나 unsigned staging을 production artifact로 대체하지 않습니다.

## 5. Production package

Production identity와 첫 parity version은 다음과 같습니다.

| Platform | Identity | Version | Required artifacts |
| --- | --- | --- | --- |
| Windows | `dev.wndls.clockrhythm` | `1.0.0+1` | portable x64 ZIP, signed MSIX |
| Android | `dev.wndls.clockrhythm` | `1.0.0+1` | production-signed APK, production-signed AAB |

Source와 모든 platform evidence가 production 자격을 충족한 뒤 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/package_windows.ps1 -Flavor Production -Artifact All
powershell -ExecutionPolicy Bypass -File tool/package_android.ps1 -Flavor Production -Artifact Apk
powershell -ExecutionPolicy Bypass -File tool/package_android.ps1 -Flavor Production -Artifact AppBundle
```

기본 output은 다음과 같습니다.

- `artifacts/windows/clock-rhythm-production-1.0.0+1-windows-x64.zip`
- `artifacts/windows/clock-rhythm-production-1.0.0+1-windows-x64.msix`
- `artifacts/android/clock-rhythm-production-1.0.0+1.apk`
- `artifacts/android/clock-rhythm-production-1.0.0+1.aab`

Production ZIP 자체의 signing status는 `unsigned`로 기록됩니다. MSIX와 Android artifacts만 제공된 외부 credential과 일치하는 signature를 요구합니다. 모든 package와 evidence가 준비된 다음 production completeness gate를 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/check_release_evidence.ps1 -ReleaseTier Production
```

이 gate가 Pending legacy row, platform matrix, backup roundtrip, installed update, artifact/hash/signing 불일치를 하나라도 보고하면 version 문자열과 무관하게 production release를 중단하고 beta로 유지합니다.

## 6. Artifact 재검사

Package wrapper가 최종 artifact를 자동 검사하지만, 전달받은 파일이나 보관본은 명시적으로 다시 검사할 수 있습니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/verify_artifact.ps1 -Platform Windows -Type PortableZip -Flavor Beta -ArtifactPath 'artifacts/windows/clock-rhythm-beta-0.1.0+1-windows-x64.zip'
powershell -ExecutionPolicy Bypass -File tool/verify_artifact.ps1 -Platform Android -Type Apk -Flavor Beta -ArtifactPath 'artifacts/android/clock-rhythm-beta-0.1.0+1.apk'
```

Production에서는 `-Type Msix`, `-Type Apk`, `-Type AppBundle`과 production path를 각각 사용합니다. 보관본의 재검사는 manifest를 바꾸지 않습니다. Manifest 기록은 같은 source snapshot에서 build와 검사를 연속 수행하는 package wrapper가 소유합니다. 수동 기록이 꼭 필요하면 `tool/source_snapshot.ps1`의 `Get-ClockRhythmSourceSnapshotSha256` 결과를 `-SourceSnapshotSha256`과 함께 넘겨야 하며, 다른 snapshot의 기존 artifact record는 무효화됩니다.

Verifier는 artifact 종류에 따라 다음을 확인합니다.

- flavor identity, display name, version name과 build number
- Windows x64 runtime DLL/data/assets와 compiled identity
- MSIX package identity, StartupTask, certificate signature
- Android application ID, min API 24, target API 36, Arm32/Arm64 및 개발용 x64 ABI
- Android signature와 production keystore certificate 일치
- artifact SHA-256, size, source snapshot SHA-256과 manifest record

Generated `artifacts/manifest.json`, checksum과 binary는 source control에서 제외된 release output입니다. [`artifacts/manifest.example.json`](../../artifacts/manifest.example.json)만 schema 예시입니다. 실제 manifest와 evidence는 동일 artifact hash를 유지하는 release storage에 함께 보관합니다.

## 7. Install, update와 cutover

Clock Rhythm에는 self-updater가 없습니다. Portable ZIP/MSIX/APK/AAB update는 사용자 또는 store가 수행하며, 기존 private database를 열어 transactional schema migration을 적용해야 합니다.

- Windows ZIP과 MSIX는 clean install과 previous-version update를 Windows 10/11에서 각각 확인합니다.
- Android APK/AAB는 API 24/31/33/36과 physical device에서 install/update 후 Preferences와 Todo가 유지되는지 확인합니다.
- beta와 production side-by-side install에서 storage, mutex/task, notification, automatic-start registration이 섞이지 않는지 확인합니다.
- 실제 cutover는 [Neutralino 마이그레이션 가이드](../migration/neutralino-to-flutter.md)의 backup 기반 순서만 사용합니다.

Package script는 자기 staging directory만 정리합니다. 사용자 설치, old/beta private data 또는 자동 시작 등록을 제거하지 않습니다. Update 실패 때 database downgrade나 reverse migration을 시도하지 않습니다.

## 8. 배포 묶음과 외부 작업

각 release record에는 최소 다음을 연결합니다.

- source revision과 artifact SHA-256
- `artifacts/manifest.json`과 checksum
- 공통/플랫폼 gate 결과
- Windows/Android matrix와 actual v1 roundtrip, installed-update evidence
- signing status와 certificate digest; credential 값은 제외
- 알려진 blocker와 최종 beta/production decision
- [Product Asset Notice](../../ASSET_NOTICE.md)와 [Third-Party Theme Notices](../../THIRD_PARTY_NOTICES.md)

Asset notice는 icon과 bundled MP3의 provenance가 확인되지 않은 distribution risk를 기록합니다. Release owner가 권리를 확인하거나 cleared replacement를 제공하기 전에는 이 위험을 숨기지 않습니다.

Artifact가 이 절차를 통과한 뒤에도 Microsoft Store/Google Play account 등록, listing 작성, policy declaration과 upload/submission은 별도 release-owner 작업입니다. 저장소 command가 이를 자동 수행하거나 credential을 저장하지 않습니다.
