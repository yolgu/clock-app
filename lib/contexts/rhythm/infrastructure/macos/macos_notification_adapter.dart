import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../application/ports/notification_port.dart';
import '../../application/ports/rhythm_start_capability.dart';

final class MacOSNotificationAdapter
    implements NotificationPort, RhythmStartCapability {
  MacOSNotificationAdapter({
    required this.onActivated,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final void Function() onActivated;
  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onActivated();
      },
    );
  }

  @override
  Future<void> show(RhythmNotification notification) {
    return _plugin.show(
      id: 41001,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        macOS: DarwinNotificationDetails(presentSound: false),
      ),
    );
  }

  @override
  Future<RhythmStartCapabilityResult> requestForExplicitStart() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: false);
    // The clock and app audio remain usable when system alerts are disabled.
    return const RhythmStartCapabilityResult.granted();
  }

  @override
  Future<void> openSettings(RhythmStartFailure failure) async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.openAppNotificationSettings();
  }
}
