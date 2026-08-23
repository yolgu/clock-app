# Clock Rhythm

Clock Rhythm is a personal productivity system that combines a configurable daily focus-and-rest cadence with dated Todos.

## Language

**Clock Rhythm**:
The complete productivity product, including rhythm guidance, Todos, preferences, and user-managed backup and restore.
_Avoid_: Clock App

**Portable Backup**:
A user-exported, schema-versioned, plain-JSON replacement package containing durable Preferences and Todos.
_Avoid_: Android System Backup, synchronization

**Compatibility Theme**:
A theme that preserves a legacy backup identifier while presenting a redistributable replacement palette and display name.
_Avoid_: Theme alias

**Daily Rhythm**:
A recurring local-time window, which may cross midnight, within which Focus Intervals and Rest Intervals alternate.
_Avoid_: Work hours

**Daily Rhythm Window**:
One calendar occurrence of the Daily Rhythm, identified by its local start instant even when it ends after midnight.
_Avoid_: Calendar day, 24-hour duration

**Focus Interval**:
A user-configured period of focused activity within the Daily Rhythm.
_Avoid_: Pomodoro

**Rest Interval**:
A user-configured break that follows a Focus Interval within the Daily Rhythm.
_Avoid_: Idle time

**Rhythm Event**:
The boundary that announces the end of a Focus Interval or Rest Interval.
_Avoid_: Alarm

**Rhythm Session**:
The user's current activation state for Rhythm Events: Idle, Running, Paused, or Stopped for Today. Running may wait for the next Daily Rhythm Window without creating a new countdown.
_Avoid_: Timer

**Idle**:
The Rhythm Session state with no registered future Rhythm Events, requiring an explicit Start before delivery resumes.
_Avoid_: Pause, waiting for the next Daily Rhythm

**Rhythm Settings Draft**:
Device-local, uncommitted edits to Focus Interval, Rest Interval, Daily Rhythm, or Windows automatic startup that never affect scheduling until explicitly saved.
_Avoid_: Preferences, active configuration

**Mute**:
Suppression of Rhythm Event sound while keeping the corresponding operating-system notification visible.
_Avoid_: Disable notifications

**Custom Notification Sound**:
A user-selected MP3 copied into Clock Rhythm's Windows application storage for Rhythm Event playback.
_Avoid_: Linked media file, Android notification sound

**Pause**:
An indefinite suspension of a Rhythm Session that preserves the Daily Rhythm's original clock boundaries until the user explicitly resumes it.
_Avoid_: Stop for Today

**Stop for Today**:
A suspension of Rhythm Events for the remainder of the current Daily Rhythm, automatically cleared at the next Daily Rhythm start.
_Avoid_: Pause, quit

**Todo**:
A dated personal commitment with a title, optional time, completion state, and user-defined display order; one installation holds at most 25,000 Todos.
_Avoid_: Calendar event

**Todo Title**:
A trimmed, single-line description of a Todo containing between 1 and 160 user-perceived characters.
_Avoid_: Note, details

**Todo Time**:
An optional local wall-clock label attached to a Todo for reference; it does not schedule a notification or affect ordering.
_Avoid_: Reminder, Rhythm Event

**Completion Group**:
The incomplete or completed partition of Todos on one Local Calendar Date, within which the user controls display order.
_Avoid_: Status list

**Local Calendar Date**:
The device-calendar date assigned to a Todo without a time zone or UTC conversion.
_Avoid_: Timestamp
