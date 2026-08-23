# Preserve drafts and own desktop notification sounds

A Rhythm Settings Draft survives route changes, tray hiding, Android configuration changes, and restorable process death in device-local state, but it never changes the active rhythm configuration until Save succeeds. The interface marks it as unsaved and offers an explicit discard action. A successful save or confirmed Portable Backup import resets the draft from durable Preferences; drafts are excluded from every backup.

Clock and schedule inputs always use an unambiguous 24-hour representation, including `HH:mm` for persisted and editable times, regardless of an operating-system 12-hour preference. Calendar dates, month labels, weekdays, and explanatory copy remain localized to Korean or English.

Windows preserves the existing Custom Notification Sound contract: selection accepts a single MP3 no larger than 20 MiB and copies it atomically into private application storage after both structural and decoder validation. It never depends on the selected source path afterward, and the copied media is not portable backup data. Preview and Rhythm Event playback each run once without looping and clear their playing state at the end. Pause, Stop for Today, and Quit stop current event audio; a new event restarts playback from the beginning. If custom decoding or playback later fails, the current event falls back to the bundled sound and the settings UI exposes a repair action without silently discarding the preference.

Changing language or Android Mute while a Rhythm Session is active replaces future Android registrations at the same occurrence times so their localized copy and sound behavior are current. Windows reads the latest sound and language choice at delivery time. Any sound-mode change stops an active preview.
