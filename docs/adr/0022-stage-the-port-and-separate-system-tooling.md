# Stage the port and separate system tooling

The repository documents but does not silently perform workstation provisioning. Flutter and FVM, Visual Studio with Desktop development with C++, Android Studio, Android SDK and tools for API 36, and successful Windows and Android `flutter doctor` checks are prerequisites. Android SDK license review and acceptance remains an explicit user action.

The independent repository contains GitHub Actions definitions without creating a remote or pushing it. A pinned Windows job formats, analyzes, tests, checks generated and architecture files, and builds Windows artifacts; an Android job runs the shared gates and builds APK and AAB artifacts with the same Flutter version.

Implementation proceeds through verified vertical stages: toolchain and project shell; domain models, legacy backup fixtures, and Drift; application shell, routing, localization, themes, and Preferences; Todo and Calendar; Rhythm and Windows adapters; Android alarm and lifecycle delivery; then backup presentation, accessibility, cutover guidance, and packaging. Each stage remains executable and passes its relevant gates before the next platform risk is added.

Native code stays minimal and application-local. Kotlin delivery code lives under `android/app`, and Windows single-instance and automatic-start integration lives under `windows/runner`; neither becomes a speculative local plugin package. Dart reaches both only through context-owned platform ports and contract tests.

The completed repository includes Flutter source, tests, ADRs and `CONTEXT.md`, setup and usage documentation, migration and verification checklists, asset and dependency notices, and reproducible build scripts. Windows ZIP and development-signed Android APK are verified without production credentials. Signed production MSIX and AAB artifacts are created only after the release owner supplies signing material outside source control.
