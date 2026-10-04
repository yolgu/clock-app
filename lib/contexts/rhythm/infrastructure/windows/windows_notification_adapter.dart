import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../application/ports/notification_port.dart';

final class WindowsNotificationIdentity {
  const WindowsNotificationIdentity({
    required this.appName,
    required this.appUserModelId,
    required this.activationGuid,
  });

  final String appName;
  final String appUserModelId;
  final String activationGuid;
}

final class WindowsNotificationRequest {
  const WindowsNotificationRequest({
    required this.id,
    required this.groupId,
    required this.groupTitle,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String groupId;
  final String groupTitle;
  final String title;
  final String body;
  final String payload;

  String get replacementTag => id.toString();
}

typedef WindowsNotificationActivation = Future<void> Function(String payload);

abstract interface class WindowsNotificationPlugin {
  Future<bool> initialize({
    required WindowsNotificationIdentity identity,
    required WindowsNotificationActivation onActivated,
  });

  Future<void> show(WindowsNotificationRequest request);

  Future<void> dispose();
}

final class FlutterLocalNotificationsWindowsPlugin
    implements WindowsNotificationPlugin {
  FlutterLocalNotificationsWindowsPlugin({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool> initialize({
    required WindowsNotificationIdentity identity,
    required WindowsNotificationActivation onActivated,
  }) async {
    final bool? initialized = await _plugin.initialize(
      settings: InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: identity.appName,
          appUserModelId: identity.appUserModelId,
          guid: identity.activationGuid,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null) {
          unawaited(onActivated(payload));
        }
      },
    );
    return initialized ?? false;
  }

  @override
  Future<void> show(WindowsNotificationRequest request) {
    // flutter_local_notifications_windows assigns this ID to the native
    // ToastNotification.Tag. WindowsNotificationDetails has no separate tag.
    return _plugin.show(
      id: request.id,
      title: request.title,
      body: request.body,
      payload: request.payload,
      notificationDetails: NotificationDetails(
        windows: WindowsNotificationDetails(
          audio: WindowsNotificationAudio.silent(),
          header: WindowsHeader(
            id: request.groupId,
            title: request.groupTitle,
            arguments: request.payload,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _plugin
        .resolvePlatformSpecificImplementation<
          FlutterLocalNotificationsWindows
        >()
        ?.dispose();
  }
}

enum WindowsNotificationFailureCode { notInitialized, initializationFailed }

final class WindowsNotificationFailure implements Exception {
  const WindowsNotificationFailure({required this.code});

  final WindowsNotificationFailureCode code;

  @override
  String toString() => 'WindowsNotificationFailure(${code.name})';
}

final class WindowsNotificationAdapter implements NotificationPort {
  factory WindowsNotificationAdapter({
    required WindowsNotificationIdentity identity,
    required WindowsNotificationActivation onActivated,
    WindowsNotificationPlugin? plugin,
  }) {
    return WindowsNotificationAdapter._(
      identity,
      onActivated,
      plugin ?? FlutterLocalNotificationsWindowsPlugin(),
    );
  }

  WindowsNotificationAdapter._(this.identity, this._onActivated, this._plugin);

  static const int activeRhythmNotificationId = 41001;
  static const String activeRhythmReplacementTag =
      '$activeRhythmNotificationId';
  static const String rhythmNotificationGroupId = 'clock-rhythm.rhythm';
  static const String clockRoutePayload = '/clock';

  final WindowsNotificationIdentity identity;
  final WindowsNotificationActivation _onActivated;
  final WindowsNotificationPlugin _plugin;
  bool _initialized = false;
  bool _disposed = false;

  Future<void> initialize() async {
    if (_disposed) {
      throw StateError('A disposed notification adapter cannot initialize.');
    }
    if (_initialized) {
      return;
    }
    final bool initialized = await _plugin.initialize(
      identity: identity,
      onActivated: _onActivated,
    );
    if (!initialized) {
      throw const WindowsNotificationFailure(
        code: WindowsNotificationFailureCode.initializationFailed,
      );
    }
    _initialized = true;
  }

  @override
  Future<void> show(RhythmNotification notification) {
    if (!_initialized || _disposed) {
      return Future<void>.error(
        const WindowsNotificationFailure(
          code: WindowsNotificationFailureCode.notInitialized,
        ),
      );
    }
    return _plugin.show(
      WindowsNotificationRequest(
        id: activeRhythmNotificationId,
        groupId: rhythmNotificationGroupId,
        groupTitle: identity.appName,
        title: notification.title,
        body: notification.body,
        payload: clockRoutePayload,
      ),
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_initialized) {
      await _plugin.dispose();
    }
    _initialized = false;
  }
}
