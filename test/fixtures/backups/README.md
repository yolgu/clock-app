# Backup fixture provenance

The Neutralino reference source is commit
`f05a7a4b3349fec7c129d2a2a6a6cf4be1de8db9` from the read-only
`clock-app` repository.

`neutralino-v1-full.json` is the unchanged UTF-8 text captured from the
reference `ExportBackupUseCase`. The use case was executed under the reference
Vitest runtime with a fixed clock, complete preferences, one timed Todo, and
one completed Todo. Its SHA-256 is
`D102F0AEE7033D5067126B1D7C6554F8773F2BF061A7FE2E2EE1511BA2EA7DD4`.

`neutralino-v1-full-flutter-canonical.json` is the exact output of decoding
that export and encoding it with `BackupV1Codec`. Both the original export and
the Flutter canonical bytes were then imported into separate reference
repositories through the actual Neutralino `ImportBackupUseCase`. Their full
`UserPreferencesSnapshot` and `TodoItemSnapshot` arrays compared equal before
the accepted result was captured as
`neutralino-v1-full-imported-semantics.json`.

The canonical fixture SHA-256 is
`BEF9F9E263B226F505D8333AE74774DDE92F6323C0CE0A3E1A153F7BEAB7AE65`, and
the imported semantics fixture SHA-256 is
`1426C41D38372E61D0710D3A29772DEDEB960887EA06A1F8B1B73BD3CB4F20DC`.

`synthetic-v1-additive-fields-and-microseconds.json` is intentionally not a
Neutralino export. It exercises additive-field tolerance and sub-millisecond
timestamp normalization independently of the byte-compatible fixture.
