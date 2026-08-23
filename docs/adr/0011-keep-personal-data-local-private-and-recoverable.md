# Keep personal data local, private, and recoverable

The first release has no account, application-managed cloud synchronization, analytics, remote crash reporting, or other application-originated network traffic. Durable data is stored without application-level encryption in operating-system private application storage. Release diagnostics must not contain Todo titles or complete user-selected file paths.

On Android, operating-system backup may copy only durable Preferences and Todos through device-to-device transfer or cloud backup when client-side encryption is available. Rhythm Session state, scheduled-notification identifiers, permission state, diagnostics, and device-specific paths stay in storage excluded from system backup. This preserves normal Android recovery without turning transient delivery state into portable product data.

Database schema migrations are transactional and verified before release. A migration or corruption failure never silently initializes an empty database: the original database is preserved and a recovery screen offers retry, Portable Backup import, or an explicitly confirmed reset to a new database.
