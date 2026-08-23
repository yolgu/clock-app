# Portable Backup round-trip evidence

- Qualification: Pending
- Actual Neutralino export: Pending
- Beta import and verification: Pending
- Beta v1 re-export: Pending
- Production import and verification: Pending

The checked-in Neutralino fixtures prove codec compatibility in automated tests, but they do not replace the required installed cutover rehearsal.

## Required rehearsal

1. Quit or pause the active Neutralino Rhythm source and preserve a pre-cutover v1 backup.
2. Import that exact v1 file into the isolated Flutter beta through preview and explicit confirmation.
3. Verify redacted Preferences and Todo semantics without recording titles or custom paths.
4. Export a new v1 file from the accepted beta and record its SHA-256.
5. Import the beta export into production through preview and explicit confirmation.
6. Verify semantic parity, reselect custom MP3 media locally, and retain all previous stores for rollback.

Evidence must bind the Neutralino source commit, beta and production artifact hashes, both JSON hashes, environment, date, and result. Portable Backup is readable plain JSON and must be stored outside the repository.
