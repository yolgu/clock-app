# Windows release matrix

- Qualification: Partial — Windows 11 existing-user portable evidence only
- Artifact SHA-256: `e5fc939e60b57ff858721d3d4eba303103f3ee2c9eb935f6425857b7ab432c35` (current beta portable ZIP)

Record results against one exact artifact from `artifacts/manifest.json`. Do not reuse a result after the artifact hash changes.

| Environment | Portable launch | Window restore | Tray and quit | Single instance | Autostart | Custom MP3 | Backup | Narrator | MSIX install/update |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Windows 10 x64, clean user | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| Windows 11 x64, clean user | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| Windows 11 x64, existing user | Passed | Pending | Pending | Passed | Pending | Pending | Passed | Pending | Pending |

Each completed cell must record Windows build, clean/existing-user state, artifact SHA-256, execution date, and a redacted result reference. Custom paths, Todo titles, certificates, and credentials must not be copied into evidence.

The existing-user row is bound to `local-evidence-20260823-portable-backup-roundtrip` and the package lifecycle run on 2026-08-23. The runtime-tested beta ZIP hash was `9a950f0960ef015029c0ee9e08c6542d9682c1e48179498d75f81ea60b5d184c`; the current archive was regenerated after a test-only scroll-observation correction. All extracted runtime files were byte-identical except `clock_rhythm.exe` build timestamps; its code, data, unwind, resources, relocations, Dart `app.so`, DLLs, assets, and notices were identical. The current package lifecycle run also passed portable launch and flavor isolation. This does not substitute for a clean-user run, tray/audio observation, Windows 10, or MSIX installation evidence.
