---
id: production-signing-material
status: needs-user
created_at: 2026-08-23T18:27:07+09:00
logical_agent_name: release-qualification
affected_task: P20/P22 signed production artifacts
blocking_scope: signed-production-artifacts-only
user_action_required: true
---

# Blocker: production signing material

## Scope

Implementation, the verified beta Windows ZIP, the development-signed beta APK, and the actual Portable Backup round trip are not blocked. Only signed production MSIX/AAB creation and the resulting production release qualification require user-provided signing material.

## Required external inputs

Provide existing credential files and values through a temporary release-owner environment outside the repository:

- Windows: `CLOCK_RHYTHM_WINDOWS_CERTIFICATE`, `CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD`
- Android: `CLOCK_RHYTHM_ANDROID_KEYSTORE`, `CLOCK_RHYTHM_ANDROID_KEY_ALIAS`, `CLOCK_RHYTHM_ANDROID_STORE_PASSWORD`, `CLOCK_RHYTHM_ANDROID_KEY_PASSWORD`

The certificate and keystore paths must point to existing files outside the repository. Do not write credential values into this report, `tool/signing.env.example.ps1`, source files, shell history, build logs, or artifact manifests.

## Resume condition

In an isolated release-owner environment, inject the variables above and run the production MSIX and App Bundle package commands from [the release process](../../docs/release/release-process.md). Resume qualification only after artifact inspection confirms the expected production identity, signature, source snapshot, and checksum.

Windows 10/clean-user installation, Android physical-device lifecycle, installed updates, and manual accessibility remain external evidence requirements documented in the release matrices; they do not require signing credentials and are not active blocker reports.
