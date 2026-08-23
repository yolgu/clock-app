# Use Riverpod, Drift, and go_router as the Flutter foundation

The Flutter app will use Riverpod Notifier APIs for feature-scoped presentation state and dependency assembly, Drift over one SQLite database for transactional local persistence with logically context-owned tables, and `go_router` for typed application navigation. These dependencies add framework conventions and generation or migration work, but provide test overrides, atomic backup replacement, durable schema evolution, and explicit navigation state across Windows and Android.
