import '../../contexts/preferences/public.dart'
    show
        AutoStartPort,
        NotificationSoundFilePort,
        PreferencesRepairStatePort,
        SoundPreviewPort,
        UserPreferences;
import '../../contexts/preferences/public_presentation.dart'
    show DeliveryPermissionActions, PreferencesPlatformCapabilities;
import '../../contexts/rhythm/public.dart'
    show
        DeliveryRecoveryPort,
        RhythmDeliveryPort,
        RhythmStartCapability,
        RhythmStatusSink;
import '../../contexts/rhythm/public_presentation.dart' show RhythmActions;
import '../platform_presentation_profile.dart';

typedef DeliveryPayloadRefresh =
    Future<void> Function(UserPreferences preferences);
typedef PlatformSoundRefresh =
    Future<void> Function(UserPreferences preferences);
typedef PlatformAudioStop = Future<void> Function();
typedef PlatformServicesDispose = Future<void> Function();
typedef PlatformRhythmActionsBinder =
    Future<void> Function(RhythmActions actions);

final class AppPlatformServices {
  const AppPlatformServices({
    required this.presentationProfile,
    required this.preferencesCapabilities,
    required this.autoStart,
    required this.notificationSoundFile,
    required this.preferencesRepairState,
    required this.soundPreview,
    required this.rhythmDelivery,
    required this.rhythmStartCapability,
    required this.rhythmStatusSink,
    required this.refreshDeliveryPayload,
    required this.refreshSound,
    required this.stopActiveAudio,
    required this.bindRhythmActions,
    required this.dispose,
    this.deliveryPermissionActions,
    this.deliveryRecovery,
  });

  final PlatformPresentationProfile presentationProfile;
  final PreferencesPlatformCapabilities preferencesCapabilities;
  final AutoStartPort autoStart;
  final NotificationSoundFilePort notificationSoundFile;
  final PreferencesRepairStatePort preferencesRepairState;
  final SoundPreviewPort soundPreview;
  final RhythmDeliveryPort rhythmDelivery;
  final RhythmStartCapability rhythmStartCapability;
  final RhythmStatusSink rhythmStatusSink;
  final DeliveryPermissionActions? deliveryPermissionActions;
  final DeliveryRecoveryPort? deliveryRecovery;
  final DeliveryPayloadRefresh refreshDeliveryPayload;
  final PlatformSoundRefresh refreshSound;
  final PlatformAudioStop stopActiveAudio;
  final PlatformRhythmActionsBinder bindRhythmActions;
  final PlatformServicesDispose dispose;
}
