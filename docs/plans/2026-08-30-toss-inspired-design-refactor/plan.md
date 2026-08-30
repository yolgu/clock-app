# Toss-inspired Clock Rhythm design refactor plan

## 1. Executive Summary

Clock Rhythm의 Windows·Android presentation을 토스증권에서 추출한 색상 계층, 4/8px 리듬,
낮은 반경, 평면형 panel, 200ms 상태 전환으로 재정렬한다. 기존 열한 theme ID, 열 개 비기본
palette, Riverpod 상태, GoRouter 경로, local-first 데이터와 접근성 계약은 유지한다. 가장 큰
리스크는 현재 작업 트리의 미커밋 디자인 변경을 보존하면서 theme·golden을 함께 바꾸는 것이며,
focused TDD, 기능별 diff, 실제 Windows 렌더링, Android build로 이를 통제한다.

## 2. Extracted Context

- User goal: 토스증권 화면을 디자인 토큰 원본으로 삼아 현재 Flutter 앱 전체 디자인을 리팩터링한다.
- Current situation: 공통 token, card, theme component, feature presentation, golden에 걸친 미커밋
  변경이 이미 존재한다. 관련 기준선 23개 테스트는 통과했다.
- Constraints: Windows 10/11 x64와 Android API 24+만 지원한다. 기존 사용자 변경을 덮지 않는다.
  새 dependency, Toss 자산, 브랜드, proprietary font는 추가하지 않는다.
- Existing assets: 승인된 [설계 명세](../../superpowers/specs/2026-08-30-toss-inspired-design-refactor-design.md),
  [source research](../../research/www.tossinvest.com/), `ThemeCatalog`, `ClockRhythmTheme`,
  `ClockRhythmCard`, adaptive layout, accessibility·golden tests.
- Assumptions: 기본 `Clock Rhythm` theme만 Toss-inspired palette로 바꾸고 열 개 compatibility
  theme는 source swatch를 유지한다. 기능과 copy는 바꾸지 않는다.
- Open questions: 없음. Android 실렌더링은 연결 기기 부재가 계속되면 build 증거까지만 확정하고
  그 한계를 최종 보고한다.

## 3. Success Criteria

| Goal | Measure | Verification |
| ---- | ------- | ------------ |
| G1. 토스형 시각 언어 | 기본 palette, 4/8 rhythm, 4/8/10/12 radius, flat panel, 52px Windows nav가 승인값과 일치 | token/component tests, Windows screenshots, golden inspection |
| G2. Theme 호환 | 11개 ID 순서 유지, 10개 비기본 source swatch 불변, 모든 theme contrast 통과 | catalog and contrast tests |
| G3. 단일 진실 공급원 | geometry·motion·type은 `design_tokens.dart`, palette는 `theme_catalog.dart`, semantic derivation은 `clock_rhythm_theme.dart`가 소유 | symbol search, architecture check, code review |
| G4. 플랫폼·접근성 보존 | Windows keyboard/focus, Android 48dp, 200% text, ko/en, compact/wide가 통과 | navigation/widget/accessibility tests and target QA |
| G5. 검증 가능한 완료 | full analyze/test, Windows beta build, Android beta APK build, 닫힌 `VISUAL_QA.md` | repository commands and evidence artifacts |

## 4. Scope Guard

### In scope

- Default theme palette와 모든 theme의 semantic derivation.
- Shared spacing, radius, type, motion, adaptive inset, card contract.
- Material component themes와 Windows top navigation.
- 현재 design token을 소비하는 presentation 파일과 관련 tests/goldens.
- Windows actual-render QA와 Android beta APK build.

### Out of scope

- Domain, application, repository, database, backup schema, notification scheduling.
- Route 추가·삭제, navigation destination 순서 변경, copy rewrite.
- Light-theme preference, source web layout 복제, custom charts, Toss asset/font.
- Production signing, packaging publication, analytics, account, cloud sync.

### Revisit triggers

- 새 token을 적용하려면 `ThemePreference` serialization이 바뀌어야 할 때.
- custom Windows non-client chrome가 필요해질 때.
- Android 48dp 또는 200% text를 지키면서 승인 hierarchy를 표현할 수 없을 때.
- 기존 미커밋 변경과 같은 줄에서 기능 동작 수정이 발견될 때.

## 5. Architecture / System Model

- Domain concepts: visual source swatch, semantic color role, spatial token, platform presentation
  profile, panel, destination state.
- Components: `ThemeCatalog` -> `ClockRhythmTheme`/extension -> shared tokens/card -> Windows/Android
  shell -> feature presentation widgets.
- Public interfaces: 기존 constructors, `ThemeCatalog.resolve`, `ClockRhythmTheme.build`, exported
  shared UI symbols를 유지한다. 새 public abstraction은 두 실제 consumer와 안정된 계약이 없으면
  만들지 않는다.
- Data/state flow: persisted `ThemePreference` -> catalog definition -> semantic `ThemeData` ->
  widget rendering. 사용자 command와 ViewModel transition은 변경하지 않는다.
- Storage/artifacts: source research는 `docs/research/`, approved design은 `docs/superpowers/specs/`,
  plan state는 이 디렉터리, runtime evidence는 `.superloopy/evidence/frontend/`가 소유한다.
- External dependencies: 없음. Flutter 3.44.7, Dart 3.12.2, 기존 Material/Riverpod/GoRouter를 유지한다.
- Security/privacy: 계정·네트워크·개인 데이터 전송이 없다. 실제 앱 QA는 local beta identity를
  사용하고 production credential을 요구하지 않는다.
- Failure behavior: test/analyze/build 실패를 current change, pre-existing, environment로 분류한다.
  한 feature slice 실패가 다른 user-owned diff를 되돌리는 근거가 되지 않는다.

## 6. Milestone Index

| Item | Purpose | Depends on | Parallelizable |
| ---- | ------- | ---------- | -------------- |
| [P0 - 기준선과 시각 계약 고정](items/P0.md) | 현재 상태와 evidence route를 고정 | - | false |
| [P1 - 토큰 단일 진실 공급원과 기본 팔레트 변경](items/P1.md) | 승인된 token과 default swatch 적용 | [P0](items/P0.md) | false |
| [P2 - 의미 색상과 공통 컴포넌트 테마 정렬](items/P2.md) | theme derivation과 panel/component 계약 정렬 | [P1](items/P1.md) | false |
| [P3 - Windows 상단 내비게이션을 인라인 탭으로 변경](items/P3.md) | 52px tab strip과 keyboard semantics 보존 | [P2](items/P2.md) | true |
| [P4 - 기능 화면의 토큰 소비 정리](items/P4.md) | feature presentation의 token drift 제거 | [P2](items/P2.md) | true |
| [P5 - 접근성·골든·회귀 계약 갱신](items/P5.md) | automated visual/behavior contract 고정 | [P3](items/P3.md), [P4](items/P4.md) | false |
| [P6 - 실제 타깃 검증과 최종 증거](items/P6.md) | full checks, builds, rendered QA, handoff | [P5](items/P5.md) | false |

## 7. Dependency Diagram

```text
P0 -> P1 -> P2
P2 -> P3
P2 -> P4
P3, P4 -> P5 -> P6
```

## 8. Regression Matrix

| Scenario | Setup | Action | Expected result | Locked by |
| -------- | ----- | ------ | --------------- | --------- |
| Default theme restoration | stored `current` theme ID | app start | Toss-inspired palette로 같은 ID가 복원 | P1 catalog tests |
| Compatibility theme restoration | 각 non-default stored ID | theme resolve | source swatch와 display identity 유지 | P1 catalog tests |
| Windows destination navigation | Windows profile, destination 0 | click와 arrow keys | 동일 destination callback과 selected semantics | P3 navigation tests |
| Android destination navigation | Android profile | bottom navigation tap/back | 기존 branch와 back behavior 유지 | P5 app shell tests |
| Rhythm command | idle/running/paused snapshots | start/pause/resume/stop | 명령과 visible status 불변 | P4 rhythm widget tests |
| Todo editing | existing Todo와 draft | edit/save/cancel/reorder | draft와 durable state 계약 불변 | P4 Todo tests |
| Calendar adaptation | 360/1280, ko/en, 200% text | month/date navigation | clipping 없이 compact/wide behavior 유지 | P5 accessibility/golden |
| Theme selection | current와 non-default cards | select theme | 저장 command와 swatch preview 일치 | P4/P5 preferences tests |
| Reduced motion | `disableAnimations=true` | focus/selection change | final state 즉시 반영, semantics 유지 | P2 shared tests |
| Windows minimum window | 720 x 560 | 핵심 화면 순회 | horizontal overflow와 hidden primary action 없음 | P6 actual-render QA |

## 9. Side Effect Review

| Area | Risk | Mitigation | Verification |
| ---- | ---- | ---------- | ------------ |
| User-owned worktree | 미커밋 변경 overwrite | reset/checkout 금지, file-level diff 확인, docs/source 분리 stage | `git status --short`, targeted diff |
| Theme compatibility | source swatch drift | default definition만 직접 변경, non-default list assertion | catalog tests |
| Accessibility | subtle outline가 state 전달 실패 | decoration boundary와 control outline role 분리 | contrast/focus/target tests |
| Layout | compact density가 text clipping 유발 | content-derived adaptive mode와 200% matrix 유지 | text-scale and golden tests |
| Functionality | visual refactor 중 handler/state 변경 | presentation-only scope, nearest widget regression tests | feature suites |
| Build environment | Android device 부재 | APK build를 확정하고 render limitation 명시 | device list and build log |
| Assets/licensing | source mark/font 복제 | assets inventory의 exclude 계약 유지 | asset diff and pubspec review |

## 10. Verification Commands / Checks

- Command/check: `fvm dart format --output=none --set-exit-if-changed <changed-dart-files>`
  - Expected: exit code 0.
- Command/check: focused token, theme, navigation, feature, accessibility, golden test commands in P-items.
  - Expected: every listed test exits 0; golden files are visually inspected.
- Command/check: `fvm dart run tool/check_architecture.dart`
  - Expected: boundary violations 0.
- Command/check: `fvm flutter analyze`
  - Expected: issues 0.
- Command/check: `fvm flutter test`
  - Expected: complete suite passes.
- Command/check: `powershell -ExecutionPolicy Bypass -File tool/build_windows.ps1 -Flavor Beta`
  - Expected: Windows beta release build and lifecycle checks pass.
- Command/check: `powershell -ExecutionPolicy Bypass -File tool/build_android.ps1 -Flavor Beta -Artifact Apk`
  - Expected: native unit tests and beta APK build pass.
- Command/check: real Windows screenshot and interaction matrix recorded in `VISUAL_QA.md`.
  - Expected: open finding 0.

## 11. Handoff Context

- Current status: design approved, plan written, P0 not started.
- Key decisions: token translation instead of page clone; default palette changes; compatibility palettes,
  state, routes, copy, platform navigation ownership stay stable.
- Watchouts: user-owned uncommitted changes overlap nearly every presentation file; do not reset them.
- Next operator starts from: [P0](items/P0.md), then follows dependency order and updates
  `execution-ledger.md` after each accepted artifact.
- Do not do: source asset/font download, light-theme expansion, state-management migration, broad cleanup,
  production signing, unattended golden approval.
- Missing-work prevention: use the milestone index as the complete inventory; each P-item owns one
  file; retries target only the failed P-item; P5 merges the two parallel presentation branches; P6
  checks every item status, test, build, and evidence artifact before completion.
- Context ledger: `execution-ledger.md` stores observable state, events, command results, artifacts,
  cancellation/resume state, and user intervention requests without private reasoning.

## 12. Self-Audit Before Final

- [x] 모든 Success Criteria가 검증 방법을 가진다.
- [x] 모든 P-item이 독립된 `items/P{number}.md` 파일 하나에만 존재한다.
- [x] `plan.md`가 모든 P-item을 상대 링크로 참조하고 P-item 본문을 중복하지 않는다.
- [x] 모든 P-item이 parent plan, dependency, risk, rollback, validation을 가진다.
- [x] 모든 P-ID가 유일하고 모든 dependency 링크가 실제 파일로 해석된다.
- [x] orphan P-item과 끊어진 링크가 없다.
- [x] 모든 중요한 제약이 Scope Guard에 반영되었다.
- [x] 누락 방지 전략이 있다.
- [x] 회귀 매트릭스가 있다.
- [x] 검증 명령 또는 체크가 있다.
- [x] hidden reasoning을 노출하지 않는다.
- [x] 불확실성은 Assumption/Open Question으로 분리했다.
- [x] 바로 다음 작업자가 실행 가능한 수준이다.
