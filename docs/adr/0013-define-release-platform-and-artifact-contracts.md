# Define release platform and artifact contracts

The product display name remains `Clock Rhythm`, the Flutter project and Dart package are named `clock_rhythm`, and the Windows executable is `clock_rhythm.exe`. The existing product icon is the source for the Windows application icon and Android adaptive launcher assets.

The first supported Android baseline is Android 7.0/API 24, with compile and target API 36, on phones and tablets in portrait and landscape orientations. Android release bundles support the architectures emitted by Flutter, including Arm32 and Arm64, while x64 remains available for development and emulators. Windows supports Windows 10 and 11 on x64; Windows Arm64 is deferred until every required platform plugin is verified there.

Beta distribution produces a portable Windows ZIP and a signed Android APK. Production packaging additionally produces Windows MSIX and Android AAB artifacts, but store enrollment and submission are outside the port. Release signing requires externally supplied credentials and fails clearly when they are absent; private keys and passwords never enter source control. The application has no self-updater, so installation is updated manually or by a store while durable data is retained through schema migrations.

Beta versioning begins at `0.1.0+1`, and the first production release begins at `1.0.0+1` only after feature-parity verification. The semantic build name is user-visible while an independently increasing build number supplies platform package versions.
