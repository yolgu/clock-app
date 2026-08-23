import 'package:flutter/services.dart';

import 'android_delivery_dto.dart';

const String androidRhythmMethodChannelName =
    'dev.wndls.clockrhythm/rhythm_delivery';

abstract final class AndroidRhythmChannelMethod {
  static const String status = 'status';
  static const String capabilityStatus = 'capabilityStatus';
  static const String requestStartCapability = 'requestStartCapability';
  static const String openSettings = 'openSettings';
  static const String schedule = 'schedule';
  static const String cancel = 'cancel';
  static const String replacePayload = 'replacePayload';
  static const String reconcile = 'reconcile';
  static const String auditRecovery = 'auditRecovery';
  static const String recoverExplicitly = 'recoverExplicitly';
  static const String activateClock = 'activateClock';
  static const String backgroundReady = 'backgroundReady';
  static const String completeBackgroundRefill = 'completeBackgroundRefill';
  static const String backgroundRefillFailed = 'backgroundRefillFailed';
  static const String lifecycleReady = 'lifecycleReady';
  static const String completeLifecycleReconcile = 'completeLifecycleReconcile';
  static const String lifecycleReconcileFailed = 'lifecycleReconcileFailed';
}

typedef AndroidRhythmChannelHandler =
    Future<Object?> Function(String method, Object? arguments);

abstract interface class AndroidRhythmChannel {
  Future<Object?> invoke(String method, [Object? arguments]);

  void setHandler(AndroidRhythmChannelHandler? handler);
}

final class MethodChannelAndroidRhythmChannel implements AndroidRhythmChannel {
  MethodChannelAndroidRhythmChannel({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel(androidRhythmMethodChannelName);

  final MethodChannel _methodChannel;

  @override
  Future<Object?> invoke(String method, [Object? arguments]) async {
    try {
      return await _methodChannel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (error) {
      throw AndroidRhythmDeliveryFailure(
        code: AndroidRhythmDeliveryFailureCode.parse(error.code),
        message: error.message ?? 'Android Rhythm delivery failed.',
        details: error.details,
      );
    } on MissingPluginException catch (error) {
      throw AndroidRhythmDeliveryFailure(
        code: AndroidRhythmDeliveryFailureCode.channelUnavailable,
        message: error.message ?? 'Android Rhythm channel is unavailable.',
      );
    }
  }

  @override
  void setHandler(AndroidRhythmChannelHandler? handler) {
    _methodChannel.setMethodCallHandler(
      handler == null
          ? null
          : (MethodCall call) => handler(call.method, call.arguments),
    );
  }
}

Map<Object?, Object?> requireAndroidRhythmChannelMap(
  Object? value,
  String method,
) {
  if (value is Map<Object?, Object?>) {
    return value;
  }
  throw AndroidRhythmDeliveryFailure(
    code: AndroidRhythmDeliveryFailureCode.invalidPayload,
    message: '$method returned an invalid response.',
    details: value,
  );
}
