import '../../contexts/preferences/infrastructure/android/android_sound_preview_adapter.dart';
import '../../contexts/preferences/public.dart';
import '../../contexts/preferences/public_presentation.dart';
import '../../contexts/rhythm/infrastructure/android/android_delivery_capability_adapter.dart';
import '../../contexts/rhythm/infrastructure/android/android_delivery_dto.dart';
import '../../contexts/rhythm/infrastructure/android/android_delivery_recovery_adapter.dart';
import '../../contexts/rhythm/infrastructure/android/android_rhythm_channel.dart';
import '../../contexts/rhythm/infrastructure/android/android_rhythm_delivery_adapter.dart';
import '../../contexts/rhythm/public.dart';
import '../../contexts/rhythm/public_presentation.dart' show RhythmActions;
import '../../shared/i18n/public.dart';
import '../infrastructure/platform/non_applicable_platform_adapters.dart';
import '../infrastructure/platform/platform_preferences_repair_registry.dart';
import '../platform_presentation_profile.dart';
import 'app_platform_services.dart';
import 'clock_rhythm_runtime.dart';

final class AndroidPlatformServicesFactory implements AppPlatformBootstrap {
  AndroidPlatformServicesFactory({
    PlatformPreferencesRepairRegistry? repairState,
  }) : _repairState = repairState ?? PlatformPreferencesRepairRegistry();

  final PlatformPreferencesRepairRegistry _repairState;
  final NonApplicableAutoStartAdapter _autoStart =
      const NonApplicableAutoStartAdapter();

  @override
  PlatformPresentationProfile get presentationProfile =>
      PlatformPresentationProfile.android;

  @override
  AutoStartPort get recoveryAutoStart => _autoStart;

  @override
  PreferencesRepairStatePort get preferencesRepairState => _repairState;

  @override
  Future<void> initializeBeforeRunApp() async {}

  @override
  Future<AppPlatformServices> create(ClockRhythmPlatformContext context) async {
    final AndroidSoundPreviewAdapter soundPreview = AndroidSoundPreviewAdapter(
      bundledAssetPath: BundledNotificationSound.assetPath,
    );
    final AndroidRhythmChannel channel = MethodChannelAndroidRhythmChannel();
    final AndroidRhythmDeliveryAdapter delivery = AndroidRhythmDeliveryAdapter(
      loadPlanContext: () => _loadPlanContext(context),
      activateRoute: (String route) async {
        context.router.router.go(route);
      },
      channel: channel,
    );
    final AndroidDeliveryRecoveryAdapter recovery =
        AndroidDeliveryRecoveryAdapter(
          loadPlanContext: () => _loadPlanContext(context),
          channel: channel,
        );
    final AndroidDeliveryCapabilityAdapter capability =
        AndroidDeliveryCapabilityAdapter();
    final _AndroidDeliveryPermissionActions permissionActions =
        _AndroidDeliveryPermissionActions(capability);

    return AppPlatformServices(
      presentationProfile: PlatformPresentationProfile.android,
      preferencesCapabilities: PreferencesPlatformCapabilities.android,
      autoStart: _autoStart,
      notificationSoundFile: const NoCustomNotificationSoundFileAdapter(),
      preferencesRepairState: _repairState,
      soundPreview: soundPreview,
      rhythmDelivery: delivery,
      rhythmStartCapability: capability,
      rhythmStatusSink: const NoOpRhythmStatusSink(),
      deliveryRecovery: recovery,
      deliveryPermissionActions: permissionActions,
      refreshDeliveryPayload: (UserPreferences preferences) {
        return delivery.replacePresentation(_presentationFor(preferences));
      },
      refreshSound: (UserPreferences preferences) => soundPreview.stop(),
      stopActiveAudio: soundPreview.stop,
      bindRhythmActions: (RhythmActions actions) async {},
      dispose: () async {
        delivery.dispose();
        await soundPreview.dispose();
      },
    );
  }

  @override
  Future<void> dispose() {
    return _repairState.dispose();
  }

  Future<AndroidRhythmPlanContext> _loadPlanContext(
    ClockRhythmPlatformContext context,
  ) async {
    final UserPreferences preferences = await context.settingsRepository.load();
    return AndroidRhythmPlanContext(
      configuration: context.rhythmSession.configuration,
      presentation: _presentationFor(preferences),
    );
  }

  AndroidRhythmNotificationPresentation _presentationFor(
    UserPreferences preferences,
  ) {
    final AppLocalizations localizations = lookupAppLocalizations(
      LanguageLocaleMapper.localeForPreferenceId(preferences.language.id),
    );
    final LocalizedEventMapper mapper = LocalizedEventMapper(localizations);
    return AndroidRhythmNotificationPresentation(
      focusEnded: mapper.notificationPayload(
        RhythmNotificationEvent.focusEnded,
      ),
      restEnded: mapper.notificationPayload(RhythmNotificationEvent.restEnded),
      muted: !preferences.notificationSound.isAudible,
    );
  }
}

final class _AndroidDeliveryPermissionActions
    implements DeliveryPermissionActions {
  const _AndroidDeliveryPermissionActions(this._capability);

  final AndroidDeliveryCapabilityPort _capability;

  @override
  Future<DeliveryPermissionSnapshot> load() async {
    final AndroidDeliveryCapabilityStatus status = await _capability.status();
    return DeliveryPermissionSnapshot(
      notificationGranted: status.notificationGranted,
      exactAlarmGranted: status.exactAlarmGranted,
    );
  }

  @override
  Future<void> openNotificationSettings() {
    return _capability.openSettings(RhythmStartFailure.notificationPermission);
  }

  @override
  Future<void> openExactAlarmSettings() {
    return _capability.openSettings(RhythmStartFailure.exactAlarmPermission);
  }
}
