enum DatabaseFailureKind {
  location,
  unsupportedVersion,
  openOrIntegrity,
  migrationOrData,
}

final class DatabaseFailure {
  const DatabaseFailure({required this.kind, required this.causeType});

  final DatabaseFailureKind kind;
  final String causeType;
}
