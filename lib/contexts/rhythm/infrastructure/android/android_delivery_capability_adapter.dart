import '../../application/ports/rhythm_start_capability.dart';
import 'android_delivery_dto.dart';
import 'android_rhythm_channel.dart';

final class AndroidDeliveryCapabilityStatus {
  const AndroidDeliveryCapabilityStatus({
    required this.sdkInt,
    required this.notificationGranted,
    required this.exactAlarmGranted,
    required this.failure,
  });

  final int sdkInt;
  final bool notificationGranted;
  final bool exactAlarmGranted;
  final RhythmStartFailure? failure;

  bool get isGranted => failure == null;

  factory AndroidDeliveryCapabilityStatus.fromChannelMap(
    Map<Object?, Object?> map,
  ) {
    final Object? sdkValue = map['sdkInt'];
    final Object? notificationValue = map['notificationGranted'];
    final Object? exactAlarmValue = map['exactAlarmGranted'];
    final Object? failureValue = map['failure'];
    if (sdkValue is! int ||
        sdkValue < 24 ||
        notificationValue is! bool ||
        exactAlarmValue is! bool ||
        (failureValue != null && failureValue is! String)) {
      throw const AndroidRhythmDeliveryFailure(
        code: AndroidRhythmDeliveryFailureCode.invalidPayload,
        message: 'Android delivery capability response is invalid.',
      );
    }
    final String? failureWireName = failureValue as String?;
    return AndroidDeliveryCapabilityStatus(
      sdkInt: sdkValue,
      notificationGranted: notificationValue,
      exactAlarmGranted: exactAlarmValue,
      failure: failureWireName == null
          ? null
          : _rhythmStartFailureFromWireName(failureWireName),
    );
  }
}

abstract interface class AndroidDeliveryCapabilityPort
    implements RhythmStartCapability {
  Future<AndroidDeliveryCapabilityStatus> status();
}

final class AndroidDeliveryCapabilityAdapter
    implements AndroidDeliveryCapabilityPort {
  AndroidDeliveryCapabilityAdapter({AndroidRhythmChannel? channel})
    : _channel = channel ?? MethodChannelAndroidRhythmChannel();

  final AndroidRhythmChannel _channel;

  @override
  Future<RhythmStartCapabilityResult> requestForExplicitStart() async {
    final AndroidDeliveryCapabilityStatus capability = await _invokeCapability(
      AndroidRhythmChannelMethod.requestStartCapability,
    );
    final RhythmStartFailure? failure = capability.failure;
    return failure == null
        ? const RhythmStartCapabilityResult.granted()
        : RhythmStartCapabilityResult.denied(failure);
  }

  @override
  Future<AndroidDeliveryCapabilityStatus> status() {
    return _invokeCapability(AndroidRhythmChannelMethod.capabilityStatus);
  }

  @override
  Future<void> openSettings(RhythmStartFailure failure) async {
    await _channel.invoke(
      AndroidRhythmChannelMethod.openSettings,
      <String, Object?>{'failure': _rhythmStartFailureWireName(failure)},
    );
  }

  Future<AndroidDeliveryCapabilityStatus> _invokeCapability(
    String method,
  ) async {
    final Object? response = await _channel.invoke(method);
    final Map<Object?, Object?> responseMap = requireAndroidRhythmChannelMap(
      response,
      method,
    );
    final Object? capabilityValue = responseMap['capability'];
    return AndroidDeliveryCapabilityStatus.fromChannelMap(
      capabilityValue == null
          ? responseMap
          : requireAndroidRhythmChannelMap(
              capabilityValue,
              '$method.capability',
            ),
    );
  }
}

RhythmStartFailure _rhythmStartFailureFromWireName(String value) {
  return switch (value) {
    'notificationPermission' => RhythmStartFailure.notificationPermission,
    'exactAlarmPermission' => RhythmStartFailure.exactAlarmPermission,
    'notificationAndExactAlarmPermission' =>
      RhythmStartFailure.notificationAndExactAlarmPermission,
    'deliveryUnavailable' => RhythmStartFailure.deliveryUnavailable,
    _ => throw AndroidRhythmDeliveryFailure(
      code: AndroidRhythmDeliveryFailureCode.invalidPayload,
      message: 'Unsupported Android Rhythm start failure: $value',
    ),
  };
}

String _rhythmStartFailureWireName(RhythmStartFailure failure) {
  return switch (failure) {
    RhythmStartFailure.notificationPermission => 'notificationPermission',
    RhythmStartFailure.exactAlarmPermission => 'exactAlarmPermission',
    RhythmStartFailure.notificationAndExactAlarmPermission =>
      'notificationAndExactAlarmPermission',
    RhythmStartFailure.deliveryUnavailable => 'deliveryUnavailable',
  };
}
