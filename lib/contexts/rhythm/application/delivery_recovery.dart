import '../domain/rhythm_configuration.dart';

enum DeliveryRecoveryDisposition { inactive, running, needsUserRecovery }

enum DeliveryRecoveryReason {
  deliveryInterrupted,
  permissionLost,
  registrationMissing,
  automaticReconcileFailed,
}

final class DeliveryRecoveryStatus {
  DeliveryRecoveryStatus({
    required this.disposition,
    required this.reason,
    required this.revision,
    required this.observedAt,
    required this.configuration,
  }) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must not be negative');
    }
    if (observedAt.isUtc) {
      throw ArgumentError.value(
        observedAt,
        'observedAt',
        'must be a local DateTime',
      );
    }
    if (disposition == DeliveryRecoveryDisposition.inactive) {
      if (reason != null || configuration != null) {
        throw ArgumentError(
          'Inactive delivery recovery cannot carry active state.',
        );
      }
      return;
    }
    if (configuration == null) {
      throw ArgumentError(
        'Active delivery recovery requires Rhythm configuration.',
      );
    }
    if (disposition == DeliveryRecoveryDisposition.needsUserRecovery &&
        reason == null) {
      throw ArgumentError('User-mediated delivery recovery requires a reason.');
    }
  }

  final DeliveryRecoveryDisposition disposition;
  final DeliveryRecoveryReason? reason;
  final int revision;
  final DateTime observedAt;
  final RhythmConfiguration? configuration;

  bool get canRestoreRunning =>
      disposition == DeliveryRecoveryDisposition.running;

  bool get requiresExplicitRecovery =>
      disposition == DeliveryRecoveryDisposition.needsUserRecovery;
}

abstract interface class DeliveryRecoveryPort {
  Future<DeliveryRecoveryStatus> auditForeground();

  Future<DeliveryRecoveryStatus> recoverExplicitly();
}
