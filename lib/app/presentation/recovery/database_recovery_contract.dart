enum DatabaseRecoveryReason {
  location,
  unsupportedVersion,
  openOrIntegrity,
  migrationOrData,
}

abstract interface class DatabaseRecoveryActions {
  Future<bool> retryOpen();

  Future<bool> resetAfterRecoveryCopy();
}
