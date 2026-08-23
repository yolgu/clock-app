# Portable Backup round-trip evidence

- Qualification: Passed
- Actual Neutralino export: Passed
- Beta import and verification: Passed
- Beta v1 re-export: Passed
- Production import and verification: Passed

The installed Windows portable applications completed one actual schema-version-1 round trip on 2026-08-23. This evidence qualifies Portable Backup data compatibility only; it does not qualify signed production artifacts, installed updates, the Windows 10 matrix, Android physical-device behavior, or manual accessibility.

## Bound evidence

| Field | Value |
| --- | --- |
| Environment | Windows 11 25H2 x64, existing user |
| Neutralino source | commit `f05a7a4b3349fec7c129d2a2a6a6cf4be1de8db9` |
| Runtime-tested Flutter source snapshot | SHA-256 `c34d35cf10dfcf6b44310e05a76a3bb507cf40d010f5b2f4566fa8e5f5abfa6b` |
| Runtime-tested beta portable ZIP | SHA-256 `9a950f0960ef015029c0ee9e08c6542d9682c1e48179498d75f81ea60b5d184c` |
| Runtime-tested production portable ZIP | SHA-256 `9108d2928224b0d688ec6925ce2bda90aa6685277e2e4a2574d8daf37120ddd3`; unsigned compatibility evidence |
| Current source-bound snapshot | SHA-256 `4a649d7734e63717ee39f7f536d834d6e9b248a1481b46106cace041ced230ef` |
| Current beta portable ZIP | SHA-256 `e5fc939e60b57ff858721d3d4eba303103f3ee2c9eb935f6425857b7ab432c35` |
| Current production portable ZIP | SHA-256 `71e244230510fbb6fda1a2eafbd04e2251f133075c225ca9d09c96f8b4547812`; unsigned compatibility evidence |
| Neutralino v1 JSON | SHA-256 `281ea7b5c30f344fc73882b4c267d32e3dc95066590680325aa229abc92dcf19` |
| Flutter beta v1 JSON | SHA-256 `99dfc86d3b5d9117c1e54c3bc045fca6ce19d08e3158dd354f1f30cc5ec0bac4` |
| Flutter production v1 JSON | SHA-256 `8d77e514a4211399f892c6b011660a8173ee6443313d91593281eaeef547e7e4` |
| Redacted evidence reference | `local-evidence-20260823-portable-backup-roundtrip` |

## Observed result

1. The running Neutralino source exported a real v1 JSON file while its credential store remained unread.
2. The final beta ZIP opened the file through the product preview and explicit replacement confirmation.
3. The beta re-export preserved the v1 envelope, every Preferences field, every Todo field, and the Todo count; only `exportedAt` changed.
4. The final production ZIP imported the beta re-export through the same preview and confirmation flow.
5. The production re-export again preserved the envelope, Preferences, Todo semantics, and count, with a later `exportedAt`.
6. Pre-import beta and production SQLite files, the three JSON files, and the older Neutralino private store were retained outside the repository for rollback. The source backup used the bundled default sound, so no Custom Notification Sound media path or binary was expected or recorded.
7. A test-only scroll-observation correction changed the source snapshot after the UI rehearsal, so all three packages were regenerated. For both Windows flavors, 25 extracted files were compared: 24 were byte-identical, and `clock_rhythm.exe` had identical `.text`, `.data`, `.pdata`, `.rsrc`, and `.reloc` sections. Its only content difference was the PE build timestamp in the COFF header and matching debug-directory timestamp bytes in `.rdata`; Dart `app.so`, native code, runtime DLLs, assets, and notices were unchanged. The actual UI result therefore applies to the current runtime content while both historical and current archive hashes remain explicit.

No Todo title, full selected-file path, credential value, or signing secret is stored in repository evidence.
