enum RhythmStartFailure {
  notificationPermission,
  exactAlarmPermission,
  notificationAndExactAlarmPermission,
  deliveryUnavailable,
}

final class RhythmStartCapabilityResult {
  const RhythmStartCapabilityResult._({required this.failure});

  const RhythmStartCapabilityResult.granted() : this._(failure: null);

  const RhythmStartCapabilityResult.denied(RhythmStartFailure failure)
    : this._(failure: failure);

  final RhythmStartFailure? failure;

  bool get isGranted => failure == null;
}

abstract interface class RhythmStartCapability {
  Future<RhythmStartCapabilityResult> requestForExplicitStart();

  Future<void> openSettings(RhythmStartFailure failure);
}
