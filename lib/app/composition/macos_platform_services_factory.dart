import '../../contexts/preferences/infrastructure/audio/audio_sound_preview_adapter.dart';
import '../../contexts/preferences/public.dart';
import '../../contexts/preferences/public_presentation.dart';
import '../../contexts/rhythm/infrastructure/audio/audio_event_sound_adapter.dart';
import '../../contexts/rhythm/infrastructure/macos/macos_notification_adapter.dart';
import '../../contexts/rhythm/infrastructure/timer/timer_rhythm_delivery_adapter.dart';
import '../../contexts/rhythm/public.dart';
import '../../contexts/rhythm/public_presentation.dart' show RhythmActions;
import '../../shared/i18n/public.dart';
import '../infrastructure/platform/non_applicable_platform_adapters.dart';
import '../infrastructure/platform/platform_preferences_repair_registry.dart';
import '../platform_presentation_profile.dart';
import 'app_platform_services.dart';
import 'clock_rhythm_runtime.dart';

final class MacOSPlatformServicesFactory implements AppPlatformBootstrap {
  final PlatformPreferencesRepairRegistry _repairState =
      PlatformPreferencesRepairRegistry();

  @override
  PlatformPresentationProfile get presentationProfile =>
      PlatformPresentationProfile.macos;

  @override
  AutoStartPort get recoveryAutoStart => const NonApplicableAutoStartAdapter();

  @override
  PreferencesRepairStatePort get preferencesRepairState => _repairState;

  @override
  Future<void> initializeBeforeRunApp() async {}

  @override
  Future<AppPlatformServices> create(ClockRhythmPlatformContext context) async {
    final MacOSNotificationAdapter notification = MacOSNotificationAdapter(
      onActivated: () => context.router.router.go('/clock'),
    );
    await notification.initialize();

    final AudioSoundPreviewAdapter preview = AudioSoundPreviewAdapter(
      bundledAssetPath: BundledNotificationSound.assetPath,
    );
    final AudioEventSoundAdapter sound = AudioEventSoundAdapter(
      bundledAssetPath: BundledNotificationSound.assetPath,
    );
    const NoOpRhythmStatusSink statusSink = NoOpRhythmStatusSink();
    final EvaluateRhythmEventDelivery evaluate = EvaluateRhythmEventDelivery(
      session: context.rhythmSession,
      statusSink: statusSink,
    );
    final TimerRhythmDeliveryAdapter delivery = TimerRhythmDeliveryAdapter(
      notification: notification,
      sound: sound,
      loadContext: (RhythmEvent event) => _loadDeliveryContext(context, event),
      evaluateEvent: (RhythmEvent event, DateTime observedAt) {
        return evaluate.execute(event, observedAt: observedAt);
      },
      onSoundResult: (EventSoundPlaybackResult result) {
        if (result.customRepairRequired) {
          _repairState.report(PreferencesRepairNeed.sound);
        }
      },
      onFailure: (TimerRhythmDeliveryFailure failure) {
        _repairState.report(
          failure.code == TimerRhythmDeliveryFailureCode.soundUnavailable
              ? PreferencesRepairNeed.sound
              : PreferencesRepairNeed.notificationPayload,
        );
      },
    );

    Future<void> stopAudio() async {
      await preview.stop();
      await sound.stop();
    }

    return AppPlatformServices(
      presentationProfile: presentationProfile,
      preferencesCapabilities: PreferencesPlatformCapabilities.macos,
      autoStart: recoveryAutoStart,
      notificationSoundFile: const NoCustomNotificationSoundFileAdapter(),
      preferencesRepairState: _repairState,
      soundPreview: preview,
      rhythmDelivery: delivery,
      rhythmStartCapability: notification,
      rhythmStatusSink: statusSink,
      refreshDeliveryPayload: (UserPreferences preferences) async {},
      refreshSound: (UserPreferences preferences) => stopAudio(),
      stopActiveAudio: stopAudio,
      bindRhythmActions: (RhythmActions actions) async {},
      dispose: () async {
        await delivery.dispose();
        await sound.dispose();
        await preview.dispose();
      },
    );
  }

  Future<RhythmDeliveryContext> _loadDeliveryContext(
    ClockRhythmPlatformContext context,
    RhythmEvent event,
  ) async {
    final UserPreferences preferences = await context.settingsRepository.load();
    final AppLocalizations localizations = lookupAppLocalizations(
      LanguageLocaleMapper.localeForPreferenceId(preferences.language.id),
    );
    final LocalizedNotificationPayload payload =
        LocalizedEventMapper(localizations).notificationPayload(
          event.kind == RhythmEventKind.focusEnds
              ? RhythmNotificationEvent.focusEnded
              : RhythmNotificationEvent.restEnded,
        );
    final NotificationSoundPreference preference =
        preferences.notificationSound;
    return RhythmDeliveryContext(
      notification: RhythmNotification(
        event: event,
        title: payload.title,
        body: payload.body,
      ),
      sound: preference.isAudible
          ? EventSoundSelection.bundledDefault(volume: preference.volume)
          : EventSoundSelection.muted(volume: preference.volume),
    );
  }

  @override
  Future<void> dispose() => _repairState.dispose();
}
