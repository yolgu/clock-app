import 'package:flutter/services.dart';

import '../../application/ports/auto_start_port.dart';

enum WindowsAutoStartNativeStatus { synchronized, needsUserAction, error }

final class WindowsAutoStartNativeResult {
  const WindowsAutoStartNativeResult._({
    required this.desiredEnabled,
    required this.actualEnabled,
    required this.status,
    required this.errorCode,
  });

  const WindowsAutoStartNativeResult.synchronized({
    required bool desiredEnabled,
    required bool actualEnabled,
  }) : this._(
         desiredEnabled: desiredEnabled,
         actualEnabled: actualEnabled,
         status: WindowsAutoStartNativeStatus.synchronized,
         errorCode: null,
       );

  const WindowsAutoStartNativeResult.needsUserAction({
    required bool desiredEnabled,
    required bool? actualEnabled,
  }) : this._(
         desiredEnabled: desiredEnabled,
         actualEnabled: actualEnabled,
         status: WindowsAutoStartNativeStatus.needsUserAction,
         errorCode: null,
       );

  const WindowsAutoStartNativeResult.error({
    required bool desiredEnabled,
    required String errorCode,
  }) : this._(
         desiredEnabled: desiredEnabled,
         actualEnabled: null,
         status: WindowsAutoStartNativeStatus.error,
         errorCode: errorCode,
       );

  final bool desiredEnabled;
  final bool? actualEnabled;
  final WindowsAutoStartNativeStatus status;
  final String? errorCode;
}

abstract interface class WindowsAutoStartNativeGateway {
  Future<WindowsAutoStartNativeResult> reconcile({
    required bool desiredEnabled,
  });
}

final class WindowsAutoStartException implements Exception {
  const WindowsAutoStartException(this.code);

  final String code;

  @override
  String toString() => 'WindowsAutoStartException($code)';
}

final class WindowsAutoStartAdapter implements AutoStartPort {
  WindowsAutoStartAdapter({WindowsAutoStartNativeGateway? nativeGateway})
    : _nativeGateway =
          nativeGateway ?? MethodChannelWindowsAutoStartNativeGateway();

  final WindowsAutoStartNativeGateway _nativeGateway;

  @override
  Future<AutoStartReconciliation> reconcile({
    required bool desiredEnabled,
  }) async {
    final WindowsAutoStartNativeResult result = await _nativeGateway.reconcile(
      desiredEnabled: desiredEnabled,
    );
    if (result.desiredEnabled != desiredEnabled) {
      throw const FormatException(
        'Windows autostart response does not match the requested state',
      );
    }
    switch (result.status) {
      case WindowsAutoStartNativeStatus.synchronized:
        if (result.actualEnabled != desiredEnabled ||
            result.errorCode != null) {
          throw const FormatException(
            'Invalid synchronized Windows autostart response',
          );
        }
      case WindowsAutoStartNativeStatus.needsUserAction:
        if (result.errorCode != null) {
          throw const FormatException(
            'Invalid needs-action Windows autostart response',
          );
        }
      case WindowsAutoStartNativeStatus.error:
        final String? errorCode = result.errorCode;
        if (errorCode == null || !_isValidErrorCode(errorCode)) {
          throw const FormatException('Invalid Windows autostart error');
        }
        throw WindowsAutoStartException(errorCode);
    }
    return AutoStartReconciliation(
      desiredEnabled: desiredEnabled,
      actualEnabled: result.actualEnabled,
    );
  }

  bool _isValidErrorCode(String value) {
    return RegExp(r'^[A-Za-z][A-Za-z0-9._-]{0,63}$').hasMatch(value);
  }
}

final class MethodChannelWindowsAutoStartNativeGateway
    implements WindowsAutoStartNativeGateway {
  MethodChannelWindowsAutoStartNativeGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'clock_rhythm/windows_auto_start';

  final MethodChannel _channel;

  @override
  Future<WindowsAutoStartNativeResult> reconcile({
    required bool desiredEnabled,
  }) async {
    final Object? response;
    try {
      response = await _channel.invokeMethod<Object?>(
        'reconcile',
        <String, bool>{'desiredEnabled': desiredEnabled},
      );
    } on PlatformException {
      throw const WindowsAutoStartException('nativeChannelFailure');
    }
    if (response is! Map<Object?, Object?> ||
        response.length != 4 ||
        !response.keys.every(
          (Object? key) =>
              key is String &&
              const <String>{
                'desiredEnabled',
                'actualEnabled',
                'status',
                'errorCode',
              }.contains(key),
        )) {
      throw const FormatException('Invalid Windows autostart response');
    }
    final Object? responseDesired = response['desiredEnabled'];
    final Object? actual = response['actualEnabled'];
    final Object? status = response['status'];
    final Object? errorCode = response['errorCode'];
    if (responseDesired is! bool ||
        (actual != null && actual is! bool) ||
        status is! String ||
        (errorCode != null && errorCode is! String)) {
      throw const FormatException('Invalid Windows autostart field type');
    }
    return switch (status) {
      'synchronized' when actual is bool && errorCode == null =>
        WindowsAutoStartNativeResult.synchronized(
          desiredEnabled: responseDesired,
          actualEnabled: actual,
        ),
      'needsUserAction' when errorCode == null =>
        WindowsAutoStartNativeResult.needsUserAction(
          desiredEnabled: responseDesired,
          actualEnabled: actual as bool?,
        ),
      'error' when errorCode is String => WindowsAutoStartNativeResult.error(
        desiredEnabled: responseDesired,
        errorCode: errorCode,
      ),
      _ => throw const FormatException(
        'Invalid Windows autostart status combination',
      ),
    };
  }
}
