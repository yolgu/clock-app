import 'package:flutter/widgets.dart';

import '../../application/delivery_recovery.dart';
import '../../domain/rhythm_configuration.dart';
import 'android_delivery_dto.dart';
import 'android_rhythm_channel.dart';

final class AndroidDeliveryRecoveryAdapter implements DeliveryRecoveryPort {
  factory AndroidDeliveryRecoveryAdapter({
    required AndroidRecoveryPlanContextLoader loadPlanContext,
    AndroidRhythmChannel? channel,
    AndroidRhythmDeliveryPlanFactory planFactory =
        const AndroidRhythmDeliveryPlanFactory(),
  }) {
    return AndroidDeliveryRecoveryAdapter._(
      loadPlanContext,
      channel ?? MethodChannelAndroidRhythmChannel(),
      planFactory,
    );
  }

  AndroidDeliveryRecoveryAdapter._(
    this._loadPlanContext,
    this._channel,
    this._planFactory,
  );

  final AndroidRecoveryPlanContextLoader _loadPlanContext;
  final AndroidRhythmChannel _channel;
  final AndroidRhythmDeliveryPlanFactory _planFactory;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<DeliveryRecoveryStatus> auditForeground() {
    return _serialized<DeliveryRecoveryStatus>(_auditForeground);
  }

  @override
  Future<DeliveryRecoveryStatus> recoverExplicitly() {
    return _serialized<DeliveryRecoveryStatus>(() async {
      final DeliveryRecoveryStatus current = await _auditForeground();
      if (!current.requiresExplicitRecovery) {
        throw const AndroidRhythmDeliveryFailure(
          code: AndroidRhythmDeliveryFailureCode.invalidPayload,
          message:
              'Android Rhythm delivery does not require explicit recovery.',
        );
      }
      final AndroidRhythmPlanContext context = await _loadPlanContext();
      final AndroidRhythmDeliveryPlan replacement = _planFactory
          .forReconciliation(
            observedAt: current.observedAt,
            context: context,
            currentRevision: current.revision,
          );
      final Object? response = await _channel.invoke(
        AndroidRhythmChannelMethod.recoverExplicitly,
        replacement.toChannelMap(),
      );
      return _parseAuditResponse(
        response,
        AndroidRhythmChannelMethod.recoverExplicitly,
      );
    });
  }

  Future<DeliveryRecoveryStatus> _auditForeground() async {
    final Object? response = await _channel.invoke(
      AndroidRhythmChannelMethod.auditRecovery,
    );
    return _parseAuditResponse(
      response,
      AndroidRhythmChannelMethod.auditRecovery,
    );
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final Future<void> previous = _operationTail;
    final Future<T> result = previous.then<T>((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}

typedef AndroidRecoveryPlanContextLoader =
    Future<AndroidRhythmPlanContext> Function();

DeliveryRecoveryStatus _parseAuditResponse(Object? response, String method) {
  final Map<Object?, Object?> map = requireAndroidRhythmChannelMap(
    response,
    method,
  );
  final String lifecycleReason = _readString(
    map['lifecycleReason'],
    'lifecycleReason',
  );
  if (lifecycleReason != 'foreground') {
    throw AndroidRhythmDeliveryFailure(
      code: AndroidRhythmDeliveryFailureCode.invalidPayload,
      message: 'Foreground recovery returned an unsupported lifecycle reason.',
    );
  }
  final int revision = _readNonNegativeInteger(map['revision'], 'revision');
  final DateTime observedAt = DateTime.fromMillisecondsSinceEpoch(
    _readNonNegativeInteger(
      map['observedAtEpochMillis'],
      'observedAtEpochMillis',
    ),
  );
  final DeliveryRecoveryDisposition disposition = _parseDisposition(
    _readString(map['disposition'], 'disposition'),
  );
  final Object? recoveryReasonValue = map['recoveryReason'];
  final DeliveryRecoveryReason? reason = recoveryReasonValue == null
      ? null
      : _parseRecoveryReason(
          _readString(recoveryReasonValue, 'recoveryReason'),
        );
  final Object? configurationValue = map['configuration'];
  final RhythmConfiguration? configuration = configurationValue == null
      ? null
      : decodeAndroidRhythmConfiguration(
          requireAndroidRhythmChannelMap(
            configurationValue,
            '$method.configuration',
          ),
        );
  try {
    return DeliveryRecoveryStatus(
      disposition: disposition,
      reason: reason,
      revision: revision,
      observedAt: observedAt,
      configuration: configuration,
    );
  } on ArgumentError catch (error) {
    throw AndroidRhythmDeliveryFailure(
      code: AndroidRhythmDeliveryFailureCode.invalidPayload,
      message: 'Android Rhythm recovery response is inconsistent: $error',
    );
  }
}

DeliveryRecoveryDisposition _parseDisposition(String value) {
  return switch (value) {
    'inactive' => DeliveryRecoveryDisposition.inactive,
    'running' => DeliveryRecoveryDisposition.running,
    'needsUserRecovery' => DeliveryRecoveryDisposition.needsUserRecovery,
    _ => throw AndroidRhythmDeliveryFailure(
      code: AndroidRhythmDeliveryFailureCode.invalidPayload,
      message: 'Unsupported Android Rhythm recovery disposition: $value',
    ),
  };
}

DeliveryRecoveryReason _parseRecoveryReason(String value) {
  return switch (value) {
    'deliveryInterrupted' => DeliveryRecoveryReason.deliveryInterrupted,
    'permissionLost' => DeliveryRecoveryReason.permissionLost,
    'registrationMissing' => DeliveryRecoveryReason.registrationMissing,
    'automaticReconcileFailed' =>
      DeliveryRecoveryReason.automaticReconcileFailed,
    _ => throw AndroidRhythmDeliveryFailure(
      code: AndroidRhythmDeliveryFailureCode.invalidPayload,
      message: 'Unsupported Android Rhythm recovery reason: $value',
    ),
  };
}

int _readNonNegativeInteger(Object? value, String field) {
  if (value is int && value >= 0) {
    return value;
  }
  throw AndroidRhythmDeliveryFailure(
    code: AndroidRhythmDeliveryFailureCode.invalidPayload,
    message: 'Android Rhythm recovery $field is invalid.',
  );
}

String _readString(Object? value, String field) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw AndroidRhythmDeliveryFailure(
    code: AndroidRhythmDeliveryFailureCode.invalidPayload,
    message: 'Android Rhythm recovery $field is invalid.',
  );
}

@pragma('vm:entry-point')
Future<void> androidRhythmLifecycleMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runAndroidRhythmLifecycleReconciliation(
    channel: MethodChannelAndroidRhythmChannel(),
  );
}

Future<void> runAndroidRhythmLifecycleReconciliation({
  required AndroidRhythmChannel channel,
  AndroidRhythmDeliveryPlanFactory planFactory =
      const AndroidRhythmDeliveryPlanFactory(),
}) async {
  int? expectedRevision;
  try {
    final Object? response = await channel.invoke(
      AndroidRhythmChannelMethod.lifecycleReady,
    );
    final AndroidRhythmBackgroundRequest request =
        AndroidRhythmBackgroundRequest.fromChannelMap(
          requireAndroidRhythmChannelMap(
            response,
            AndroidRhythmChannelMethod.lifecycleReady,
          ),
        );
    expectedRevision = request.expectedRevision;
    final AndroidRhythmDeliveryPlan replacement = planFactory
        .forBackgroundRefill(request);
    await channel.invoke(
      AndroidRhythmChannelMethod.completeLifecycleReconcile,
      <String, Object?>{
        'expectedRevision': request.expectedRevision,
        'plan': replacement.toChannelMap(),
      },
    );
  } on Object catch (error) {
    await _reportLifecycleFailure(
      channel: channel,
      expectedRevision: expectedRevision,
      error: error,
    );
  }
}

Future<void> _reportLifecycleFailure({
  required AndroidRhythmChannel channel,
  required int? expectedRevision,
  required Object error,
}) async {
  final String failureCode = switch (error) {
    final AndroidRhythmDeliveryFailure failure => failure.code.wireName,
    FormatException() =>
      AndroidRhythmDeliveryFailureCode.invalidPayload.wireName,
    _ => AndroidRhythmDeliveryFailureCode.backgroundRefillFailed.wireName,
  };
  try {
    await channel.invoke(
      AndroidRhythmChannelMethod.lifecycleReconcileFailed,
      <String, Object?>{
        'expectedRevision': expectedRevision,
        'failureCode': failureCode,
      },
    );
  } on Object {
    // Native no-backup state already owns the durable recovery marker.
  }
}
