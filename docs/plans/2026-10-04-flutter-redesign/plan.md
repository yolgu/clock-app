# Clock Rhythm 내부 구조 전환

화면과 동작, 저장 형식과 플랫폼 지원 범위를 보존하면서 관련 작업을 서비스로 묶고 공유 데이터와 화면 상태의 소유자를 분리한다. 기준은 [설계안](../../../outputs/2026-10-04-clock-rhythm-flutter-redesign.md)이다.

## 범위와 성공 기준

- 할 일 변경과 조회 서비스를 실제 소비자에 연결하고 이전 단일 작업 클래스를 제거한다.
- 캘린더 선택과 탐색을 공유 데이터 갱신에서 분리한다.
- 저장 설정, 설정 편집과 미리듣기의 상태를 분리하고 앱 루트가 저장 설정을 구독하게 한다.
- 리듬 명령을 하나의 세션 서비스로 연결하고 공통 타이머와 오디오 구현을 플랫폼 전용 구현에서 구분한다.
- 백업의 원자성, 부분 성공, 초기화와 실패 복구를 보존한다.
- 기존 macOS 실행 추가 변경을 보존한다. 새 기능, 데이터 마이그레이션, 의존성 업그레이드와 새 운영 차단 검사는 범위 밖이다.

## 구조와 계약

화면 입력은 상태 소유자와 응집된 서비스를 거쳐 기존 도메인 규칙과 저장소, 플랫폼 계약으로 전달한다. 앱 조립은 실제 구현 선택과 수명을 담당한다. 저장소는 영속 데이터의 권위자이고 공통 화면 데이터는 그 조회 결과다. 성공은 반환값, 실패는 구체적인 예외, 저장 후 복구 필요 상태는 결과로 전달한다. 외부 전송과 배포는 없다.

## 작업 목록

| 작업 | 목적 | 선행 | 병렬 |
| --- | --- | --- | --- |
| [기준 확보(P0)](items/P0.md) | 도구체인과 변경 전 검증 | 없음 | 아니오 |
| [할 일(P1)](items/P1.md) | 서비스와 상태 소유권 전환 | P0 | 아니오 |
| [설정(P2)](items/P2.md) | 서비스와 편집, 재생 상태 분리 | P1 | 아니오 |
| [리듬과 플랫폼(P3)](items/P3.md) | 세션 서비스와 공통 구현 | P2 | 아니오 |
| [통합 검증(P4)](items/P4.md) | 백업과 앱 전체 연결, 최종 확인 | P3 | 아니오 |

의존 순서: P0 → P1 → P2 → P3 → P4. 상태와 세부 검증 결과는 각 작업 파일에서 관리한다.

## 회귀와 부수 효과

| 시나리오 | 보존 기준 | 검증 위치 |
| --- | --- | --- |
| 할 일 수정과 날짜 선택 | 한 번의 변경, 두 화면 갱신, 최신 선택과 자정 처리 | 기존 할 일 application, presentation 테스트 |
| 설정 저장과 초안 | 저장 실패 시 초안 보존, 테마와 언어의 즉시 반영 | 기존 설정 application, presentation 테스트 |
| 소리와 리듬 | 중복 실행, 늦은 완료, 정지와 자원 해제 | 리듬과 소리 구현 테스트 |
| 백업 복원 | 설정과 할 일 함께 교체, 실패 시 기존 데이터 보존 | replacement_atomicity, data_transfer 테스트 |
| 화면과 구조 | 기존 경로, 접근성, 공개 경계 | navigation, accessibility, architecture 테스트 |

## 공통 검증

고정 도구체인은 Flutter 3.44.7과 Dart 3.12.2다. PowerShell 실행기는 현재 환경에 없으므로 기존 검증 스크립트의 Dart 형식, 구조 검사, 정적 분석과 전체 테스트 명령을 FVM으로 직접 실행한다. 이번 변경은 생성 선언을 바꾸지 않아 생성물 전체 해시 비교는 수행하지 않는다. 플랫폼 빌드는 가능한 호스트에서 수행하고 Windows 및 Android 실기기 확인은 별도 한계로 기록한다.

명령: `fvm dart format --output=none --set-exit-if-changed lib test integration_test tool`, `fvm dart run tool/check_architecture.dart`, `fvm flutter analyze --no-pub`, `fvm flutter test --no-pub`.

## 작업 기록과 복구

초기 상태에는 macOS 실행 추가 파일과 기존 미커밋 변경이 있다. 각 작업은 최신 파일을 기준으로 반영하며 전체 작업 트리를 초기화하지 않는다. 구조 변경이 실패하면 해당 변경과 소비자만 같은 단위로 되돌린다. 진행 중 중단되면 현재 In Progress 항목의 미완료 조건부터 재개한다. 새 승인 대기나 배포 작업은 없다.

기준 테스트 출력은 `/tmp/clock-refactor-baseline.log`에 남긴다. 최종 결과는 이 계획과 각 작업의 결과에 기록하며, 기존 설계안은 설계 근거로 보존한다.

## 구현 결과

모든 작업의 코드 전환과 소비자 연결을 마쳤다. 최종 검증과 환경 한계는 [통합 검증 결과](items/P4.md)에 기록했다.

| 책임 | 현재 구현 |
| --- | --- |
| 할 일 변경과 조회 | [변경 서비스](../../../lib/contexts/todo/application/todo_command_service.dart), [조회 서비스](../../../lib/contexts/todo/application/todo_query_service.dart) |
| 할 일 공유 데이터와 캘린더 탐색 | [공통 데이터](../../../lib/contexts/todo/presentation/todo_data_controller.dart), [캘린더 선택](../../../lib/contexts/todo/presentation/calendar/calendar_view_model.dart) |
| 설정 처리 | [즉시 설정](../../../lib/contexts/preferences/application/preferences_service.dart), [주기와 초안](../../../lib/contexts/preferences/application/rhythm_settings_service.dart), [알림 소리](../../../lib/contexts/preferences/application/notification_sound_service.dart) |
| 설정 화면 상태 | [저장 설정](../../../lib/contexts/preferences/presentation/preferences_data_controller.dart), [초안 편집](../../../lib/contexts/preferences/presentation/settings/rhythm_settings_editor.dart), [미리듣기](../../../lib/contexts/preferences/presentation/sound/sound_preview_controller.dart) |
| 세션과 예약 조정 | [리듬 서비스](../../../lib/contexts/rhythm/application/rhythm_service.dart) |
| 공통 플랫폼 구현 | [타이머 전달](../../../lib/contexts/rhythm/infrastructure/timer/timer_rhythm_delivery_adapter.dart), [이벤트 오디오](../../../lib/contexts/rhythm/infrastructure/audio/audio_event_sound_adapter.dart), [미리듣기 오디오](../../../lib/contexts/preferences/infrastructure/audio/audio_sound_preview_adapter.dart) |
| 전체 연결과 가져오기 후 갱신 | [앱 조립](../../../lib/app/composition/clock_rhythm_runtime.dart), [가져오기 갱신](../../../lib/app/infrastructure/provider_data_import_refresh_adapter.dart) |

할 일 저장소의 기존 전체 조회 계약을 활용해 불변 컬렉션 하나를 공유하고 날짜별 목록과 월별 집계를 파생한다. 캘린더 이동은 저장 데이터를 별도로 복제하지 않는다. 월별 집계는 표시용 상태를 만들 때 한 번 계산한다.

백업은 설정 저장소를 직접 사용하지 않고 공개 설정 서비스를 통해 읽는다. 기존 구조 검사 규칙을 그대로 유지한다. 서비스 통합 후 사용하지 않는 단일 작업 클래스는 제거했으며, 백업과 주기 미리보기처럼 독립된 흐름이나 계산은 유지한다.

검증 요약: 형식, 정적 분석과 기능 경계 검사 통과, 전체 테스트 623개 통과와 기존 실패 8개 유지, 최종 macOS Debug 빌드 성공. 새로운 배포나 운영 데이터 변경은 없다.
