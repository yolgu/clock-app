# Make the Flutter cutover explicit and reversible

Neutralino, Flutter beta, and Flutter production installations keep independent application data and automatic-start registrations. Beta imports the automatic-start preference and may register its own launcher, but every automatic launch is Idle. The first beta Start displays a coexistence warning asking the user to pause or quit the Neutralino application before enabling a second rhythm source.

Migration is deliberately user-driven: export schema-version-1 JSON from Neutralino and import it into beta, then export another schema-version-1 file from the accepted beta and import it into production. Custom Notification Sound media is reselected for each installation because it is not part of Portable Backup.

Production never deletes or edits the Neutralino or beta executable, private store, or automatic-start entry. Its cutover guide orders the user to create backups, quit and disable automatic startup in the previous application, import and verify production data, reselect custom media, and only then uninstall older applications manually. Until that verification, the previous stores and a pre-cutover Portable Backup provide rollback; there is no automatic database downgrade or reverse migration.
