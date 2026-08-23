# Pin the toolchain and isolate platform plugins

Development pins Flutter 3.44.7 with a committed `.fvmrc`, and commits `pubspec.lock`; local and continuous-integration commands execute through FVM. The SDK cache is not committed. Flutter availability and a clean `flutter doctor` for Windows and Android are prerequisites because the current workstation does not expose Flutter on `PATH`.

The core dependency set begins with `flutter_riverpod` 3.4.x, `go_router` 17.5.x, `drift` 2.34.x, and `drift_flutter` 0.3.x. Only Drift and Flutter localization use code generation. Four explicit routes and hand-written immutable domain objects do not add Riverpod Generator, Freezed, go_router_builder, GetIt, or another injection framework.

Platform adapters may use `window_manager`, `tray_manager`, `flutter_local_notifications`, `file_picker`, `audioplayers`, and `path_provider`, with `msix` as packaging tooling. `shared_preferences` is limited to replaceable, noncritical device UI state. Every plugin remains behind a product-owned port and contract test so package replacement does not leak through application or domain code.

Critical Android Rhythm Session and registration state is written atomically by the Kotlin delivery adapter in Android no-backup storage and coordinated with `AlarmManager`; it does not rely on asynchronously flushed shared preferences. Windows automatic startup uses a product-owned, package-aware adapter capable of passing `--hidden`, rather than adopting a plugin API that cannot express the required launch contract.

Dependencies use stable pub.dev releases and a committed lockfile, never an unpinned Git branch or private fork. An upgrade is an isolated change that reruns the supported platform matrix, and redistributable licenses are surfaced in the application and release artifacts.
