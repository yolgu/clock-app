# Enforce one instance and one active Rhythm notification

Windows permits one running Clock Rhythm instance per beta or production identity. A second interactive launch asks the existing instance to show and focus its window, while a `--hidden` automatic-start launch never surfaces an already running instance. Android notification activation reuses the existing navigation task and selects `/clock` instead of creating a parallel stack.

Android maintains one active Rhythm Event notification, replacing it at the next boundary. Windows uses a stable notification group and tag where its package identity supports replacement; notification-center history beyond the active item follows operating-system policy rather than application-managed retention.
