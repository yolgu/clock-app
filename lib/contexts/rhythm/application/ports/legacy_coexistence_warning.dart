abstract interface class LegacyCoexistenceWarning {
  Future<bool> shouldWarnBeforeStart();

  Future<void> acknowledge();
}

final class NoLegacyCoexistenceWarning implements LegacyCoexistenceWarning {
  const NoLegacyCoexistenceWarning();

  @override
  Future<void> acknowledge() async {}

  @override
  Future<bool> shouldWarnBeforeStart() async => false;
}
