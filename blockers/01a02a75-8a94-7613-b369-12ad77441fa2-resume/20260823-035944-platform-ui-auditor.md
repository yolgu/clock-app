# Platform/UI audit blocked by concurrent source mutation

## Status

- Audit status: Blocked before a final P10–P17 snapshot could be certified.
- Blocker: Files inside the assigned P14/P16/P17 read scope changed while the audit was in progress.
- Changed by this audit: this blocker report only.
- No source, test, documentation, generated output, build artifact, dependency cache, Git state, or external system was modified by this audit.

## Conflict evidence and impact

The audit began from the repository state around 2026-08-23 03:59 Asia/Seoul. During read-only tracing, the Windows state implementation changed from the initially enumerated shared-preferences file to `local_app_data_window_state_store.dart`; its content changed again between hash snapshots taken after 04:12 and at 04:21. The Android delivery coordinator, bridge, Dart adapter, Windows runner, native harness, and unrelated verification fixtures also received later timestamps during the same audit window. Build/test processes belonging to other work were briefly active and Windows/Android build-owned files were updated.

Because the requested result is the exact current status of interrupted P10–P17 work, especially current compile and lifecycle risks, mixing evidence from those snapshots could incorrectly report a defect that was just repaired or miss a newly introduced one. The P14 window-state and P16/P17 delivery portions therefore require one stable post-worker snapshot before certification.

## Preliminary matrix from the last inspected snapshots

| Item | Preliminary status | Evidence present | Unfinished or unsafe to certify |
| --- | --- | --- | --- |
| P10 | Partial | Preferences ViewModel, draft restoration widgets/store, platform capability UI, theme/sound panels, and focused tests exist. | Production entrypoint does not use the runtime; platform repair state is half-wired; confirmed import does not reliably resynchronize mounted raw form controllers; no goldens. |
| P11 | Partial, implementation otherwise substantial | Todo ViewModel/editor/list/calendar, midnight reconciliation, keyboard/semantic reorder, and focused widget tests exist. | Product entrypoint still supplies placeholder pages, so the feature is not reachable in the shipped app path; no goldens. |
| P12 | Partial, implementation otherwise substantial | Clock/Rhythm ViewModel, state-aware controls, visible-only ticker, semantics, and focused tests exist. | Product entrypoint still supplies placeholders; no direct ClockPage integration test or goldens. |
| P13 | Partial | Data transfer state machine/UI, streaming 32 MiB adapter, recovery UI/bootstrap/importer, and application/adapter tests exist. | Bootstrap is not used by `main`; recovery import bypasses the required preview/confirm flow; mounted Preferences controls can retain a pre-import draft; normal/recovery import repair propagation is incomplete; presentation tests are absent. |
| P14 | Partial | Pre-engine single-instance runner, close-to-hide, hidden launch handling, native autostart, window/tray adapters, local-state work, tests, and a native harness exist. | No Windows platform-services factory or production binding exists; tray Quit/application-command ordering is absent; the final window-state implementation changed during audit; stored maximized state is at risk with the current bootstrap/first-frame ordering; durable pass evidence was not available in the ledger. |
| P15 | Partial | Windows notification, event/preview audio, private MP3 adoption, fallback, and focused adapter tests exist. | All production constructor searches found only definitions and tests; no factory initializes or disposes them, no real delivery context/evaluator is wired, and asynchronous repair results do not reach Preferences. No real Windows event evidence. |
| P16 | Partial | Manifest policy, capability gate, DTO/parser, revisioned no-backup state, exact alarm scheduler, receiver, notification publisher, headless refill, Dart/Kotlin tests exist. | Android services are not connected to the product entrypoint and currently participate in a separate compile blocker; emulator/instrumentation/physical delivery evidence is absent. The delivery files changed during audit. |
| P17 | Partial | Lifecycle receiver/decision table, startup audit, headless reconciliation, Dart recovery adapter, backup allowlists, tests, and a device checklist exist. | `DeliveryRecoveryPort` has no runtime or presentation consumer; every runtime session is created Idle; Running restoration and explicit recovery UI are absent; real backup/reboot/Doze/force-stop evidence is absent. The lifecycle implementation changed during audit. |

## Stable critical findings that must be rechecked after the workspace settles

1. **The actual product entrypoint still renders placeholders.** `lib/main.dart:5-8` calls `AppComposition.buildApp()`. `lib/app/composition/app_composition.dart:17-40` creates a router without product pages and returns `ClockRhythmApp`; `lib/app/navigation/app_router.dart:68-72` consequently selects localized placeholders. `ClockRhythmBootstrap` and `ClockRhythmRuntime.createWithPlatformFactory` have no production call sites. `openDatabase()` is also never called. This makes P10–P17 feature/platform code unreachable from the current executable.

2. **The interrupted repair-state change is a static Dart compile blocker for full analysis/tests.** `AppPlatformServices` requires `preferencesRepairState` at `lib/app/composition/app_platform_services.dart:33-55`, but the existing constructor calls in `lib/app/composition/android_platform_services_factory.dart:33-53` and `test/app/composition/clock_rhythm_runtime_test.dart:70-84` omit it. A main-only Windows build can miss this because those libraries are not reachable from the placeholder entrypoint.

3. **The repair registry is dead code.** `PlatformPreferencesRepairRegistry` has no creation or consumer call site. `PreferencesInitialData` accepts repair needs, but `ApplicationPreferencesActions.load()` returns only Preferences and draft. `PreferencesViewModel` consumes the initial set but does not subscribe to platform repair changes or resolve the registry after successful repair. Asynchronous Windows sound/delivery failures and import/autostart failures therefore cannot reliably surface or clear in the UI.

4. **Normal import can restore durable data while leaving mounted form text stale.** `ProviderDataImportRefreshAdapter.refreshAfterImport()` saves the imported draft then invalidates providers (`lib/app/infrastructure/provider_data_import_refresh_adapter.dart:31-39`). `RhythmSettingsPanel` synchronizes raw controllers only on first initialization or `saved`/`discarded` feedback (`lib/contexts/preferences/presentation/settings/rhythm_settings_panel.dart:348-366`). Because the indexed Clock branch remains mounted while importing from Data, returning to Clock can display the pre-import raw draft and a later Save can overwrite imported rhythm settings.

5. **Recovery import skips the ADR-required preview and explicit confirmation.** `DatabaseRecoveryPage._import()` directly invokes the supplied import operation (`lib/app/presentation/recovery/database_recovery_page.dart:148-168`); bootstrap passes that to `DatabaseRecoveryBackupImporter.execute()`, which decodes, archives, and replaces immediately (`lib/app/composition/database_recovery_backup_importer.dart:44-86`). There is no prepared preview/confirm boundary. Autostart reconciliation failure is swallowed at lines 79-85 without a usable repair result.

6. **Wiring Android runtime as-is would erase or misrepresent native recovery state.** Runtime creates a fresh Idle session (`lib/app/composition/clock_rhythm_runtime.dart:132-135`). `ApplicationRhythmActions.load()` delegates to general reconciliation (`lib/contexts/rhythm/presentation/rhythm_actions.dart:82-85`), whose synchronizer cancels platform delivery before scheduling (`lib/contexts/rhythm/application/reconcile_rhythm.dart:44-52`). `AndroidDeliveryRecoveryAdapter` has no consumer. A recovery-aware startup path must audit native state before this generic load; Running should restore without an implicit Start, and user-recovery state must remain available until explicit Recovery or Start.

7. **Windows adapters remain uncomposed.** Searches for `WindowsWindowAdapter`, `WindowsTrayAdapter`, `WindowsAutoStartAdapter`, `WindowsNotificationAdapter`, `WindowsRhythmDeliveryAdapter`, `WindowsEventSoundAdapter`, `WindowsSoundPreviewAdapter`, and `WindowsNotificationSoundFileAdapter` found only their definitions and focused tests. No Windows platform-services factory exists. Close-to-hide therefore leaves the current product with no tray Quit path, and no notification/audio delivery can occur.

8. **Windows maximized restoration requires a final lifecycle review.** The native runner shows the first Flutter frame using the default `restore_maximized_` value (`windows/runner/flutter_window.cpp:185-197`). The Dart adapter later loads stored state and only calls `setRestoreMaximized` (`lib/app/infrastructure/windows/windows_window_adapter.dart:96-137`). With the existing asynchronous bootstrap design, an interactive window can already be visible unmaximized and is not reactivated to apply the stored maximized state. Either first-frame visibility must wait for Dart initialization or interactive initialization must explicitly activate after setting the restore flag.

9. **Evidence contracts remain open.** The execution ledger still reports P2 as the last completed item and P10–P17 as Pending. There are no checked-in goldens, no Data Transfer presentation tests, no direct ClockPage integration test, no certified P14/P15 Windows runtime result, and no API 24/31/33/36 plus physical-device/backup evidence for P16/P17.

## Constructors and usages affected by the interrupted repair work

- `AppPlatformServices(...)`: existing calls at `lib/app/composition/android_platform_services_factory.dart:33` and `test/app/composition/clock_rhythm_runtime_test.dart:70`; both require the new repair-state argument. A Windows factory still needs to be created and must own/report/dispose the same state.
- `PreferencesInitialData(...)`: production construction at `lib/contexts/preferences/presentation/preferences_actions.dart:134`; fake constructions at `test/app/presentation/clock_rhythm_root_test.dart:145`, `test/contexts/preferences/presentation/preferences_page_test.dart:196`, and `test/contexts/preferences/presentation/preferences_view_model_test.dart:169`. The optional default prevents a compile error but leaves repair behavior untested.
- Consumers of `PreferencesInitialData`: `PreferencesViewModel.build()` at lines 23-29 and `_recoverDurablePreferences()` at lines 390-403.
- `PlatformPreferencesRepairRegistry`: definition only; no `report`, `current`, `changes`, `resolve`, or `dispose` production usage was found.
- `ClockRhythmBootstrap`, `ClockRhythmRuntime.createWithPlatformFactory`, `AndroidPlatformServicesFactory`, and `AndroidDeliveryRecoveryAdapter`: definitions exist but no production construction call was found.

## Minimum safe resume sequence

1. Wait until all workers touching P10–P17 report completion and no relevant files or platform build processes are changing.
2. Re-run broad file inventory and definition/usage searches, then re-read all files whose timestamp/hash changed, especially Windows local state/runner/harness and Android bridge/coordinator/tests.
3. Fix the required `AppPlatformServices.preferencesRepairState` call sites and establish a preferences-owned repair-state contract with initial snapshot, live stream, report/resolve, and deterministic disposal tests.
4. Add a Windows platform-services factory and a recovery-aware Android factory/runtime contract.
5. Replace the placeholder `AppComposition` path with the database bootstrap/runtime and add an entrypoint-level test proving real Clock, Todo, Data, Theme, Windows, and Android services are reachable.
6. Preserve native Android Running/user-recovery state before any generic Rhythm reconciliation; add reopen Running and explicit Recovery ViewModel/widget tests.
7. Add an import-reset signal for mounted Preferences controllers, propagate auto-start/sound repair, and route recovery import through prepare/preview/confirm.
8. Run the focused Flutter tests, then `tool/verify.ps1`; run `tool/build_windows.ps1` plus the lifecycle/flavor harness; run Android Dart tests and Gradle native tests/builds; finally execute the documented API/physical-device/backup matrices.

## Resume verification needed from the parent

- Confirm the workspace has reached a stable post-worker snapshot and record the final relevant hashes/timestamps.
- Confirm `fvm flutter analyze` reaches every formerly unreachable library and that the runtime composition test compiles.
- Confirm the executable entrypoint shows real feature keys rather than `_DestinationPlaceholder` widgets.
- Confirm Windows close/tray/Quit, stored maximized state, hidden/second launch, autostart, notification, sound fallback, and repair on a release artifact.
- Confirm Android permission denial, exact scheduling, process removal/reopen Running, reboot/update/time/timezone reconciliation, revoke/grant/force-stop user recovery, Doze skip behavior, and real backup include/exclude behavior on the required matrix.

## Resolution — 2026-08-23

- Source/local-beta blocker status: Resolved after all writers completed and the parent re-audited the stable workspace.
- Findings 1–8 were addressed by the real `AppComposition`/database bootstrap, Windows and Android platform factories, replaying repair-state port, mounted draft reload, recovery prepare/preview/confirm split, recovery-aware Android startup, pre-frame Windows initialization, and focused regression tests.
- Fresh common gate: generated output current, 320 Dart files formatted, architecture scan 225 files, analyze 0 issues, 538 tests passed.
- Fresh Windows beta package: native lifecycle/autostart harness and archive inspection passed; SHA-256 `19c0f45f7610c96344e81a1765ac743839aa24c82bc522d54e33a76b4f4962a8`.
- Fresh Android beta package: 43 native tests and APK inspection passed; SHA-256 `f64ea05c30eb7ac2d18ad5b6d77452fff9b87b8189e5dc6f31cd21514aacba00`.
- Finding 9 is intentionally not closed as production evidence: Windows 10/11 installed flows, Android emulator/physical lifecycle and backup, TalkBack/Narrator, signed production artifacts, installed updates, and actual cutover remain tracked in P22.
