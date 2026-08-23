# Clock Rhythm

Clock Rhythm은 집중과 휴식의 반복 주기인 Daily Rhythm과 날짜별 Todo를 함께 관리하는 로컬 우선 생산성 앱입니다. Windows 10/11 x64와 Android 7.0(API 24) 이상을 대상으로 하며, 계정·동기화·분석·원격 오류 수집 기능을 포함하지 않습니다.

> 현재 저장소는 beta 검증 단계입니다. 실제 Neutralino v1 → Flutter beta → Flutter production 왕복은 통과했지만, Android 실기기 수명주기, Windows 10 및 clean-user 설치·업데이트, 수동 접근성, production signing 증거가 모두 갖춰지기 전에는 `1.0.0+1` production-ready로 간주하지 않습니다. 진행 상태는 [실행 ledger](docs/plans/2026-08-22-clock-rhythm-flutter-port/execution-ledger.md)에서 확인합니다.

## 지원 범위

| 플랫폼 | 지원 계약 | 주요 플랫폼 기능 |
| --- | --- | --- |
| Windows | Windows 10/11 x64 | tray 실행, 단일 인스턴스, 자동 시작, Custom Notification Sound(MP3), 앱 볼륨 |
| Android | API 24 이상 phone/tablet | 운영체제 알림, 사용자가 허용한 exact alarm, reboot/update/time 변화 복구 |

iOS, macOS, Linux, web, Windows Arm64, 계정·클라우드 동기화와 Todo 알림은 현재 범위가 아닙니다.

Android는 foreground service를 유지하지 않습니다. Focus 또는 Rest Interval이 9분보다 짧으면 deep idle에서 알림이 지연될 수 있고, 이미 지난 boundary는 늦게 몰아서 재생하지 않고 건너뜁니다. Notification/exact-alarm permission, reboot·Doze·시간 변경은 실제 device evidence가 없으면 지원 완료로 판정하지 않습니다.

제품의 주요 기능은 다음과 같습니다.

- Daily Rhythm에 고정된 Focus Interval과 Rest Interval
- Start, Pause, Resume, Stop for Today 상태
- 날짜별 Todo 생성·편집·완료·재정렬과 월간 Calendar
- 한국어·영어, 11개 호환 theme ID
- Preferences와 Todo를 완전히 교체하는 Portable Backup v1 import/export
- 데이터베이스 시작 실패 시 Retry, Portable Backup Import, 확인된 Reset 복구 화면

## 개발 시작

도구를 자동 설치하거나 Android license를 자동 승인하는 저장소 스크립트는 없습니다. 먼저 [Windows·Android 도구체인 설정](docs/setup/windows-android-toolchain.md)을 따라 FVM, Flutter 3.44.7, Visual Studio C++ workload, Android SDK API 36을 준비합니다.

저장소 루트의 PowerShell에서 공통 검증을 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/check_docs.ps1
powershell -ExecutionPolicy Bypass -File tool/verify.ps1 -Platform All
```

한 플랫폼만 준비된 환경에서는 `-Platform Windows`, `-Platform Android`, 또는 `-Platform Core`를 사용합니다. 생성물 갱신과 상세한 CI 계약은 [CI와 로컬 품질 게이트](docs/verification/ci-gates.md)를 참고합니다.

## Build와 배포 artifact

검증용 beta build는 다음 명령으로 만듭니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/build_windows.ps1 -Flavor Beta
powershell -ExecutionPolicy Bypass -File tool/build_android.ps1 -Flavor Beta -Artifact Apk
```

이 명령이 만드는 raw build directory 자체를 ZIP, signed APK, MSIX 또는 AAB release로 오인하면 안 됩니다. 배포 가능한 beta artifact는 package wrapper로 조립·검사합니다.

```powershell
powershell -ExecutionPolicy Bypass -File tool/package_windows.ps1 -Flavor Beta -Artifact Zip
powershell -ExecutionPolicy Bypass -File tool/package_android.ps1 -Flavor Beta -Artifact Apk
```

외부 signing credential, production 명령과 자격 조건은 [release 절차](docs/release/release-process.md)를 따릅니다. Store 등록·제출, signing key 생성·보관, remote 생성·push는 저장소 자동화 범위가 아닙니다.

## Backup과 마이그레이션

Portable Backup과 Android System Backup은 서로 다른 기능입니다.

- **Portable Backup**은 사용자가 Data 화면에서 내보내고 가져오는 암호 없는 일반 JSON 파일입니다. Preferences와 Todo만 포함하고 import 시 현재 데이터를 완전히 교체합니다.
- **Android System Backup**은 적격한 암호화 cloud transport 또는 device-to-device transfer가 운영체제 private database를 복구하는 제한된 기능입니다. 사용자가 다른 플랫폼으로 옮기는 JSON 파일이 아닙니다.

Rhythm Session, 예약 ID, permission 상태, draft, window state와 device path는 어느 Portable Backup에도 들어가지 않습니다. Windows Custom Notification Sound 파일도 이동되지 않으므로 설치마다 다시 선택해야 합니다. 자세한 데이터 범위는 [privacy와 data](docs/privacy-and-data.md)를 참고합니다.

Neutralino에서 바로 production으로 private database를 복사하지 마십시오. [Neutralino → Flutter 전환 가이드](docs/migration/neutralino-to-flutter.md)는 다음의 복구 가능한 흐름을 사용합니다.

```text
Neutralino v1 export → Flutter beta import·검증 → beta v1 export → production import·검증
```

이전 앱과 beta/production은 독립된 저장소와 자동 시작 등록을 유지합니다. 이전 Rhythm source를 종료하지 않은 채 새 설치에서 Start하면 알림이 중복될 수 있습니다. Beta의 첫 Start는 Neutralino Pause·Quit 확인을 한 번 요구하며, Cancel하면 Start하지 않고 다음 시도에서 다시 묻습니다.

## 문서

- [도구체인 설정](docs/setup/windows-android-toolchain.md)
- [Neutralino 마이그레이션과 rollback](docs/migration/neutralino-to-flutter.md)
- [release 절차](docs/release/release-process.md)
- [플랫폼 검증 checklist](docs/verification/platform-checklist.md)
- [privacy와 data](docs/privacy-and-data.md)
- [troubleshooting](docs/troubleshooting.md)
- [Android lifecycle·System Backup checklist](docs/testing/android-lifecycle-checklist.md)
- [architecture decisions](docs/adr/)
- [제품 용어](CONTEXT.md)

배포 전에는 [Product Asset Notice](ASSET_NOTICE.md)와 [Third-Party Theme Notices](THIRD_PARTY_NOTICES.md)를 함께 검토하고 artifact에 포함해야 합니다.
