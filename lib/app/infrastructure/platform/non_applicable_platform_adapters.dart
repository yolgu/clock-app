import '../../../contexts/preferences/public.dart';
import '../../../contexts/rhythm/public.dart';

final class NonApplicableAutoStartAdapter implements AutoStartPort {
  const NonApplicableAutoStartAdapter();

  @override
  Future<AutoStartReconciliation> reconcile({
    required bool desiredEnabled,
  }) async {
    return AutoStartReconciliation(
      desiredEnabled: desiredEnabled,
      actualEnabled: desiredEnabled,
    );
  }
}

final class NoCustomNotificationSoundFileAdapter
    implements NotificationSoundFilePort {
  const NoCustomNotificationSoundFileAdapter();

  @override
  Future<SelectedNotificationSound?> chooseCustomMp3() async => null;
}

final class GrantedRhythmStartCapability implements RhythmStartCapability {
  const GrantedRhythmStartCapability();

  @override
  Future<RhythmStartCapabilityResult> requestForExplicitStart() async {
    return const RhythmStartCapabilityResult.granted();
  }

  @override
  Future<void> openSettings(RhythmStartFailure failure) async {}
}

final class NoOpRhythmStatusSink implements RhythmStatusSink {
  const NoOpRhythmStatusSink();

  @override
  Future<void> publish(RhythmStatusSnapshot snapshot) async {}
}
