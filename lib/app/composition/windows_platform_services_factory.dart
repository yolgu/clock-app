import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../contexts/preferences/infrastructure/windows/private_sound_store.dart';
import '../../contexts/preferences/infrastructure/windows/windows_auto_start_adapter.dart';
import '../../contexts/preferences/infrastructure/windows/windows_notification_sound_file_adapter.dart';
import '../../contexts/preferences/infrastructure/windows/windows_sound_preview_adapter.dart';
import '../../contexts/preferences/public.dart';
import '../../contexts/preferences/public_presentation.dart';
import '../../contexts/rhythm/infrastructure/windows/windows_event_sound_adapter.dart';
import '../../contexts/rhythm/infrastructure/windows/windows_notification_adapter.dart';
import '../../contexts/rhythm/infrastructure/windows/windows_tray_adapter.dart';
import '../../contexts/rhythm/public.dart';
import '../../contexts/rhythm/public_presentation.dart' show RhythmActions;
import '../../shared/i18n/public.dart';
import '../config/app_flavor.dart';
import '../infrastructure/platform/platform_preferences_repair_registry.dart';
import '../infrastructure/windows/windows_window_adapter.dart';
import '../platform_presentation_profile.dart';
import 'app_platform_services.dart';
import 'clock_rhythm_runtime.dart';

final class WindowsPlatformServicesFactory implements AppPlatformBootstrap {
  WindowsPlatformServicesFactory({
    required this.configuration,
    WindowsWindowAdapter? window,
    WindowsAutoStartAdapter? autoStart,
    PlatformPreferencesRepairRegistry? repairState,
  }) : _window =
           window ??
           WindowsWindowAdapter(
             expectedApplicationIdentity: configuration.windowsIdentity,
           ),
       _autoStart = autoStart ?? WindowsAutoStartAdapter(),
       _repairState = repairState ?? PlatformPreferencesRepairRegistry();

  final AppFlavorConfiguration configuration;
  final WindowsWindowAdapter _window;
  final WindowsAutoStartAdapter _autoStart;
  final PlatformPreferencesRepairRegistry _repairState;
  bool _initialized = false;
  bool _disposed = false;

  @override
  PlatformPresentationProfile get presentationProfile =>
      PlatformPresentationProfile.windows;

  @override
  AutoStartPort get recoveryAutoStart => _autoStart;

  @override
  PreferencesRepairStatePort get preferencesRepairState => _repairState;

  @override
  Future<void> initializeBeforeRunApp() async {
    if (_disposed) {
      throw StateError('Windows platform bootstrap is disposed.');
    }
    if (_initialized) {
      return;
    }
    await _window.initialize();
    _initialized = true;
  }

  @override
  Future<AppPlatformServices> create(ClockRhythmPlatformContext context) async {
    if (!_initialized || _disposed) {
      throw StateError('Windows platform bootstrap is not active.');
    }
    final PrivateSoundStore privateSoundStore = PrivateSoundStore(
      directoryProvider: _FlavorPrivateSoundDirectoryProvider(
        configuration.windowsIdentity,
      ),
    );
    final WindowsNotificationSoundFileAdapter notificationSoundFile =
        WindowsNotificationSoundFileAdapter(privateStore: privateSoundStore);
    final WindowsSoundPreviewAdapter soundPreview = WindowsSoundPreviewAdapter(
      bundledAssetPath: BundledNotificationSound.assetPath,
    );
    final WindowsEventSoundAdapter eventSound = WindowsEventSoundAdapter(
      bundledAssetPath: BundledNotificationSound.assetPath,
    );
    final WindowsNotificationAdapter notification = WindowsNotificationAdapter(
      identity: WindowsNotificationIdentity(
        appName: configuration.displayName,
        appUserModelId: configuration.windowsIdentity,
        activationGuid: configuration.windowsNotificationActivationGuid,
      ),
      onActivated: (String payload) async {
        if (payload != WindowsNotificationAdapter.clockRoutePayload) {
          throw const FormatException(
            'Windows notification activation must target /clock.',
          );
        }
        context.router.router.go(payload);
        await _window.open();
      },
    );
    await notification.initialize();

    late final WindowsRhythmDeliveryAdapter delivery;
    late final _WindowsPlatformCoordinator coordinator;
    final WindowsTrayAdapter tray = WindowsTrayAdapter(
      toolTip: configuration.displayName,
      onCommand: (WindowsTrayCommand command) {
        coordinator.handle(command);
      },
    );
    coordinator = _WindowsPlatformCoordinator(
      settingsRepository: context.settingsRepository,
      session: context.rhythmSession,
      clock: context.clock,
      window: _window,
      tray: tray,
      repairState: _repairState,
      stopScheduledDelivery: () => delivery.cancelScheduledEvent(),
      stopEventSound: eventSound.stop,
      stopPreview: soundPreview.stop,
    );
    final EvaluateRhythmEventDelivery evaluateDelivery =
        EvaluateRhythmEventDelivery(
          session: context.rhythmSession,
          statusSink: coordinator,
        );
    delivery = WindowsRhythmDeliveryAdapter(
      notification: notification,
      sound: eventSound,
      loadContext: (RhythmEvent event) {
        return _loadDeliveryContext(context, event);
      },
      evaluateEvent: (RhythmEvent event, DateTime observedAt) {
        return evaluateDelivery.execute(event, observedAt: observedAt);
      },
      onSoundResult: (EventSoundPlaybackResult result) {
        if (result.customRepairRequired) {
          _repairState.report(PreferencesRepairNeed.sound);
        }
      },
      onFailure: (WindowsRhythmDeliveryFailure failure) {
        _repairState.report(_repairNeedFor(failure.code));
      },
    );

    return AppPlatformServices(
      presentationProfile: PlatformPresentationProfile.windows,
      preferencesCapabilities: PreferencesPlatformCapabilities.windows,
      autoStart: _autoStart,
      notificationSoundFile: notificationSoundFile,
      preferencesRepairState: _repairState,
      soundPreview: soundPreview,
      rhythmDelivery: delivery,
      rhythmStartCapability: const _WindowsRhythmStartCapability(),
      rhythmStatusSink: coordinator,
      refreshDeliveryPayload: coordinator.refreshDeliveryPreferences,
      refreshSound: coordinator.refreshSoundPreferences,
      stopActiveAudio: coordinator.stopActiveAudio,
      bindRhythmActions: coordinator.bind,
      dispose: () => _disposeRuntime(
        coordinator: coordinator,
        delivery: delivery,
        notification: notification,
        eventSound: eventSound,
        soundPreview: soundPreview,
      ),
    );
  }

  Future<WindowsRhythmDeliveryContext> _loadDeliveryContext(
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
    return WindowsRhythmDeliveryContext(
      notification: RhythmNotification(
        event: event,
        title: payload.title,
        body: payload.body,
      ),
      sound: _eventSoundSelection(preferences.notificationSound),
    );
  }

  EventSoundSelection _eventSoundSelection(NotificationSoundPreference sound) {
    return switch (sound.mode) {
      NotificationSoundMode.bundledDefault =>
        EventSoundSelection.bundledDefault(volume: sound.volume),
      NotificationSoundMode.custom => EventSoundSelection.custom(
        privateSource: sound.privateSource!,
        volume: sound.volume,
      ),
      NotificationSoundMode.muted => EventSoundSelection.muted(
        volume: sound.volume,
      ),
    };
  }

  PreferencesRepairNeed _repairNeedFor(WindowsRhythmDeliveryFailureCode code) {
    return switch (code) {
      WindowsRhythmDeliveryFailureCode.contextUnavailable ||
      WindowsRhythmDeliveryFailureCode.notificationUnavailable =>
        PreferencesRepairNeed.notificationPayload,
      WindowsRhythmDeliveryFailureCode.soundUnavailable =>
        PreferencesRepairNeed.sound,
      WindowsRhythmDeliveryFailureCode.progressionUnavailable =>
        PreferencesRepairNeed.rhythmSchedule,
    };
  }

  Future<void> _disposeRuntime({
    required _WindowsPlatformCoordinator coordinator,
    required WindowsRhythmDeliveryAdapter delivery,
    required WindowsNotificationAdapter notification,
    required WindowsEventSoundAdapter eventSound,
    required WindowsSoundPreviewAdapter soundPreview,
  }) async {
    Object? firstFailure;
    StackTrace? firstStackTrace;
    for (final Future<void> Function() dispose in <Future<void> Function()>[
      coordinator.dispose,
      delivery.dispose,
      notification.dispose,
      eventSound.dispose,
      soundPreview.dispose,
    ]) {
      try {
        await dispose();
      } on Object catch (error, stackTrace) {
        firstFailure ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    if (firstFailure != null) {
      Error.throwWithStackTrace(firstFailure, firstStackTrace!);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    Object? firstFailure;
    StackTrace? firstStackTrace;
    try {
      await _window.dispose();
    } on Object catch (error, stackTrace) {
      firstFailure = error;
      firstStackTrace = stackTrace;
    }
    try {
      await _repairState.dispose();
    } on Object catch (error, stackTrace) {
      firstFailure ??= error;
      firstStackTrace ??= stackTrace;
    }
    if (firstFailure != null) {
      Error.throwWithStackTrace(firstFailure, firstStackTrace!);
    }
  }
}

final class _WindowsPlatformCoordinator implements RhythmStatusSink {
  _WindowsPlatformCoordinator({
    required this._settingsRepository,
    required this._session,
    required this._clock,
    required this._window,
    required this._tray,
    required this._repairState,
    required this._stopScheduledDelivery,
    required this._stopEventSound,
    required this._stopPreview,
  });

  final SettingsRepository _settingsRepository;
  final RhythmSession _session;
  final Clock _clock;
  final WindowsWindowAdapter _window;
  final WindowsTrayAdapter _tray;
  final PlatformPreferencesRepairRegistry _repairState;
  final Future<void> Function() _stopScheduledDelivery;
  final Future<void> Function() _stopEventSound;
  final Future<void> Function() _stopPreview;
  RhythmActions? _actions;
  RhythmStatusSnapshot? _latestSnapshot;
  UserPreferences? _latestPreferences;
  Future<void> _commandTail = Future<void>.value();
  Future<void> _trayTail = Future<void>.value();
  bool _trayInitialized = false;
  bool _disposed = false;

  Future<void> bind(RhythmActions actions) async {
    if (_disposed || _actions != null) {
      throw StateError('Windows Rhythm actions cannot be bound again.');
    }
    _actions = actions;
    final UserPreferences preferences = await _settingsRepository.load();
    final RhythmStatusSnapshot snapshot = await actions.load();
    _latestPreferences = preferences;
    _latestSnapshot = snapshot;
    await _tray.initialize(
      labels: _labels(preferences),
      status: snapshot.status,
    );
    _trayInitialized = true;
  }

  void handle(WindowsTrayCommand command) {
    if (_disposed) {
      return;
    }
    _commandTail = _commandTail.then((_) => _execute(command)).catchError((
      Object _,
      StackTrace _,
    ) {
      if (!_disposed) {
        _repairState.report(PreferencesRepairNeed.rhythmSchedule);
      }
    });
  }

  @override
  Future<void> publish(RhythmStatusSnapshot snapshot) async {
    _latestSnapshot = snapshot;
    await _updateTray();
  }

  Future<void> refreshDeliveryPreferences(UserPreferences preferences) async {
    final NotificationSoundPreference? previousSound =
        _latestPreferences?.notificationSound;
    _latestPreferences = preferences;
    if (previousSound != null &&
        previousSound != preferences.notificationSound) {
      await _stopEventSound();
    }
    await _updateTray();
  }

  Future<void> refreshSoundPreferences(UserPreferences preferences) async {
    _latestPreferences = preferences;
    await _stopEventSound();
  }

  Future<void> stopActiveAudio() async {
    await _stopEventSound();
    await _stopPreview();
  }

  Future<void> _execute(WindowsTrayCommand command) async {
    final RhythmActions? actions = _actions;
    if (actions == null) {
      throw StateError('Windows tray actions are not bound.');
    }
    switch (command) {
      case WindowsTrayCommand.open:
        await _window.open();
      case WindowsTrayCommand.pause:
        await actions.pause();
      case WindowsTrayCommand.resume:
        await actions.resume();
      case WindowsTrayCommand.stopForToday:
        await actions.stopForToday();
      case WindowsTrayCommand.quit:
        await _quit();
    }
  }

  Future<void> _quit() async {
    try {
      await _stopScheduledDelivery();
    } on Object {
      _repairState.report(PreferencesRepairNeed.rhythmSchedule);
    }
    try {
      await stopActiveAudio();
    } on Object {
      _repairState.report(PreferencesRepairNeed.sound);
    }
    _session.resetToIdle();
    final DateTime observedAt = _clock.now();
    await publish(
      RhythmStatusSnapshot.capture(
        session: _session,
        observedAt: observedAt,
        nextEvent: null,
      ),
    );
    await _window.requestApplicationExit();
  }

  Future<void> _updateTray() {
    if (!_trayInitialized || _disposed) {
      return Future<void>.value();
    }
    final RhythmStatusSnapshot? snapshot = _latestSnapshot;
    if (snapshot == null) {
      return Future<void>.value();
    }
    _trayTail = _trayTail.then<void>((_) async {
      final UserPreferences preferences =
          _latestPreferences ?? await _settingsRepository.load();
      _latestPreferences = preferences;
      await _tray.update(labels: _labels(preferences), status: snapshot.status);
    });
    return _trayTail;
  }

  WindowsTrayLabels _labels(UserPreferences preferences) {
    final AppLocalizations localizations = lookupAppLocalizations(
      LanguageLocaleMapper.localeForPreferenceId(preferences.language.id),
    );
    final LocalizedEventMapper mapper = LocalizedEventMapper(localizations);
    return WindowsTrayLabels(
      open: mapper.message(LocalizedEventKey.trayOpen),
      pause: mapper.message(LocalizedEventKey.trayPause),
      resume: mapper.message(LocalizedEventKey.trayResume),
      stopForToday: mapper.message(LocalizedEventKey.trayStopForToday),
      quit: mapper.message(LocalizedEventKey.trayQuit),
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _commandTail;
    await _trayTail;
    if (_trayInitialized) {
      await _tray.dispose();
    }
  }
}

final class _WindowsRhythmStartCapability implements RhythmStartCapability {
  const _WindowsRhythmStartCapability();

  @override
  Future<RhythmStartCapabilityResult> requestForExplicitStart() async {
    return const RhythmStartCapabilityResult.granted();
  }

  @override
  Future<void> openSettings(RhythmStartFailure failure) async {}
}

final class _FlavorPrivateSoundDirectoryProvider
    implements PrivateSoundDirectoryProvider {
  const _FlavorPrivateSoundDirectoryProvider(this._identity);

  final String _identity;

  @override
  Future<String> applicationSupportPath() async {
    final Directory root = await getApplicationSupportDirectory();
    return '${root.path}${Platform.pathSeparator}$_identity';
  }
}
