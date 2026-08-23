# Neutralino에서 Flutter로 안전하게 전환하기

Clock Rhythm은 Neutralino private storage나 Flutter database를 직접 읽어 옮기지 않습니다. 모든 전환은 사용자가 만든 schema-version-1 Portable Backup을 통해 다음 순서로 진행합니다.

```text
Neutralino v1 export
  → Flutter beta import와 사용 검증
  → beta v1 export
  → Flutter production import와 사용 검증
```

Neutralino, Flutter beta, Flutter production은 서로 독립된 실행 파일, private store와 자동 시작 등록을 유지합니다. 따라서 이전 설치를 보존한 채 검증하고 문제가 있으면 돌아갈 수 있습니다. 반대로 두 설치에서 Rhythm Session을 동시에 Start하면 중복 알림이 발생할 수 있으므로 아래 종료 순서를 지켜야 합니다.

## 전환 전에 알아둘 점

- Portable Backup은 암호가 없는 읽을 수 있는 JSON입니다. 개인 정보가 있는 파일처럼 안전한 위치에 보관합니다.
- import는 현재 설치의 Preferences와 Todo를 **전부 교체**합니다. merge하거나 일부 항목만 건너뛰지 않습니다.
- import preview를 확인하고 승인하기 전에는 데이터와 Rhythm Session이 바뀌지 않습니다.
- import를 승인하면 먼저 현재 설치의 예약된 Rhythm Events와 재생 중인 소리를 중단하고 Idle로 만듭니다. 이후 데이터 교체가 실패해도 해당 설치는 Idle입니다.
- Windows 자동 시작 preference는 backup에 포함되지만 운영체제 등록은 각 설치가 자기 identity로 따로 조정합니다. 자동 시작으로 실행된 Flutter 앱은 hidden 상태의 Idle이며 사용자의 Start 없이 delivery를 시작하지 않습니다.
- Windows Custom Notification Sound 파일과 device path는 backup에 포함되지 않습니다. import 후 설치마다 MP3를 다시 선택합니다.
- Portable Backup v1은 최대 32 MiB와 25,000 Todo를 허용합니다. invalid Todo 하나라도 있으면 전체 import가 거부되고 기존 durable data는 유지됩니다.

## 1. Neutralino → Flutter beta

### 1.1 Neutralino 기준 backup 만들기

1. Neutralino Clock Rhythm에서 Preferences와 Todo가 최신인지 확인합니다.
2. Neutralino의 Data 화면에서 schema-version-1 JSON을 export합니다.
3. 파일을 복사해 하나는 변경하지 않은 `pre-beta` rollback backup으로 보관합니다.
4. Neutralino의 Todo 개수, 완료 개수, 날짜 범위, Focus/Rest 간격, Daily Rhythm, 언어, theme, 자동 시작 상태를 별도 메모합니다. Todo title이나 전체 개인 파일 경로를 release evidence에 기록하지 않습니다.

### 1.2 beta에서 import하고 확인하기

1. production과 다른 identity의 Flutter beta artifact를 설치합니다.
2. beta의 **Data → Import Portable Backup**을 선택하고 Neutralino export를 엽니다.
3. preview에서 다음을 기준 메모와 비교합니다.
   - 전체/완료 Todo 수와 날짜 범위
   - Focus Interval, Rest Interval, Daily Rhythm
   - 언어와 theme ID
   - Windows 자동 시작 영향
   - export 시각
   - Custom Notification Sound가 bundled default로 바뀐다는 안내
4. 값이 다르면 Cancel합니다. Cancel은 beta 데이터나 session을 바꾸지 않습니다.
5. 값이 맞으면 전체 교체와 Rhythm 중단 안내를 확인한 뒤 Import를 승인합니다.
6. Clock, Today/Calendar, Preferences, Theme, Data 화면을 열어 Preferences와 Todo 의미가 유지되는지 확인합니다.
7. Windows에서 Custom Notification Sound를 사용했다면 beta private storage로 다시 선택하고 preview합니다.

import된 자동 시작 값이 켜져 있으면 beta는 자기 전용 등록을 가질 수 있습니다. 이는 Neutralino 등록을 비활성화하거나 수정하지 않습니다. beta 자동 시작은 hidden Idle이므로 곧바로 Rhythm Event를 만들지는 않지만, 다음 명시적 Start 전에 아래 공존 안전 절차가 필요합니다.

### 1.3 첫 beta Start 전 공존 안전 절차

1. Neutralino Rhythm Session을 Pause하거나 Stop하고 애플리케이션을 완전히 Quit합니다.
2. OS 로그인 때 Neutralino가 다시 실행되지 않도록 Neutralino의 자동 시작을 비활성화합니다.
3. Task Manager와 tray에서 Neutralino process가 남지 않았는지 확인합니다.
4. 그 다음 beta에서 Start하고 하나 이상의 Focus/Rest 경계를 확인합니다.

첫 beta Start를 누르면 Neutralino를 Pause·Quit했는지 확인하는 공존 경고가 표시됩니다. **Cancel**은 acknowledgement를 저장하지 않고 Start도 실행하지 않으므로 다음 Start에서 다시 경고합니다. **일시정지하고 종료했습니다**를 선택하면 beta identity의 device-local marker를 저장한 뒤 Start하며, marker가 유지되는 동안 다시 묻지 않습니다. Production에는 이 beta 전용 경고가 표시되지 않습니다.

이 dialog는 Neutralino process를 자동 검사하거나 종료하지 않습니다. 확인 버튼을 누르기 전에 위 수동 절차를 실제로 완료해야 하며, marker 저장에 실패하거나 beta device state를 지우면 안전을 위해 경고가 다시 표시될 수 있습니다.

### 1.4 beta 검증과 다음 backup

충분한 기간 동안 다음을 확인합니다.

- Start/Pause/Resume/Stop for Today와 다음 Daily Rhythm Window
- Todo 생성·편집·완료·재정렬과 Calendar 날짜
- 언어·theme·sound·volume·Mute
- Windows tray/자동 시작 또는 Android notification/exact-alarm 권한 흐름
- 앱 종료·재실행, 해당 플랫폼의 lifecycle 동작

beta를 받아들일 수 있을 때 beta의 Data 화면에서 새 Portable Backup v1을 export합니다. 이 파일을 `accepted-beta` 전환 backup으로 보존합니다. Neutralino export를 production에 바로 넣는 대신 이 beta export를 사용해야 beta에서 확인한 canonical v1 의미가 production으로 이어집니다.

## 2. Flutter beta → Flutter production

production 자격은 [플랫폼 checklist](../verification/platform-checklist.md)와 [실행 ledger](../plans/2026-08-22-clock-rhythm-flutter-port/execution-ledger.md)가 요구하는 증거가 모두 있을 때만 성립합니다. 단지 `production` flavor가 build된다는 이유로 전환하지 않습니다.

1. Neutralino `pre-beta` backup과 beta `accepted-beta` backup을 모두 복제해 안전하게 보관합니다.
2. beta Rhythm Session을 Pause 또는 Stop하고 beta를 완전히 Quit합니다.
3. Windows beta 자동 시작을 비활성화합니다. Neutralino도 계속 비활성 상태인지 확인합니다.
4. production artifact를 새 identity로 설치합니다. 기존 Neutralino나 beta를 uninstall하지 않습니다.
5. production의 Data 화면에서 `accepted-beta` v1을 열고 preview를 다시 비교한 뒤 승인합니다.
6. Preferences, Todo, Calendar와 theme를 검증하고 Windows Custom Notification Sound를 production에서 다시 선택합니다.
7. 이전 두 앱이 실행 중이지 않은 상태에서 production을 Start하고 delivery를 확인합니다.
8. production 설치·업데이트와 실제 데이터 유지 증거가 기록된 뒤에만 이전 앱을 사용자가 수동 uninstall할 수 있습니다.

production 애플리케이션은 Neutralino 또는 beta의 executable, private store, 자동 시작 등록을 삭제하거나 수정하지 않습니다. 이전 설치를 제거하는 결정과 작업은 검증을 마친 사용자가 직접 수행합니다.

## Rollback

전환 중 문제가 생기면 database downgrade, reverse migration 또는 private database 복사를 시도하지 않습니다.

1. 문제가 있는 Flutter 설치의 Rhythm Session을 Stop하고 애플리케이션을 Quit합니다.
2. 해당 설치의 자동 시작을 비활성화합니다.
3. 아직 보존된 이전 설치를 실행합니다. 이전 설치의 private store가 그대로라면 그 상태를 우선 확인합니다.
4. 복원이 필요할 때만 그 설치가 이해하는 v1 Portable Backup을 preview하고 import합니다.
5. 문제가 있는 설치와 그 data를 바로 삭제하지 말고 원인 분석과 필요한 evidence가 끝날 때까지 보존합니다.

production에서 생성된 SQLite database를 beta나 Neutralino에 덮어쓰지 않습니다. JSON v1보다 새로운 serialized 계약이 도입되기 전에는 backup version을 임의로 바꾸거나 낮추지 않습니다.

## Android 기기 교체와의 차이

Android System Backup은 운영체제가 적격 transport에서 Preferences와 Todo가 든 flavor별 database와 rollback journal만 복원하는 제한된 경로입니다. Rhythm delivery state, permission, draft와 device path는 복원하지 않으며 복원 후 session은 Idle이어야 합니다. 이것은 Neutralino·Windows·beta·production 사이를 사용자가 이동하는 Portable Backup 절차를 대신하지 않습니다.

Android System Backup의 실제 범위와 transport 조건은 [privacy와 data](../privacy-and-data.md), lab 검증은 [Android lifecycle·System Backup checklist](../testing/android-lifecycle-checklist.md)를 따릅니다.
