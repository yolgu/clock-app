final class AutoStartReconciliation {
  const AutoStartReconciliation({
    required this.desiredEnabled,
    required this.actualEnabled,
  });

  final bool desiredEnabled;
  final bool? actualEnabled;

  bool get repairRequired => actualEnabled != desiredEnabled;
}

abstract interface class AutoStartPort {
  Future<AutoStartReconciliation> reconcile({required bool desiredEnabled});
}
