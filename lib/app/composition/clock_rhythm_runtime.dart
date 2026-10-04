import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contexts/preferences/public.dart';
import '../../contexts/preferences/public_presentation.dart';
import '../../contexts/rhythm/public.dart' as rhythm;
import '../../contexts/rhythm/public_presentation.dart';
import '../../contexts/todo/public.dart' as todo;
import '../../contexts/todo/public_model.dart' show LocalCalendarDate;
import '../../contexts/todo/public_presentation.dart';
import '../../features/data_transfer/public.dart';
import '../../features/data_transfer/public_presentation.dart';
import '../infrastructure/coordinating_preferences_changed_port.dart';
import '../infrastructure/device_state/device_sound_locator_mutation.dart';
import '../infrastructure/device_state/device_sound_locator_store.dart';
import '../infrastructure/persistence/database_startup.dart';
import '../infrastructure/persistence/drift_backup_replacement_adapter.dart';
import '../infrastructure/persistence/repositories/drift_settings_repository.dart';
import '../infrastructure/persistence/repositories/drift_todo_repository.dart';
import '../infrastructure/provider_data_import_refresh_adapter.dart';
import '../infrastructure/rhythm_import_safety_adapter.dart';
import '../infrastructure/secure_random_todo_id_generator.dart';
import '../infrastructure/system_clock.dart';
import '../navigation/app_router.dart';
import '../navigation/app_routes.dart';
import '../platform_presentation_profile.dart';
import '../presentation/clock_page.dart';
import '../presentation/clock_rhythm_root.dart';
import 'app_platform_services.dart';

typedef AppPlatformServicesFactory =
    Future<AppPlatformServices> Function(ClockRhythmPlatformContext context);

final class ClockRhythmPlatformContext {
  const ClockRhythmPlatformContext({
    required this.settingsRepository,
    required this.rhythmSession,
    required this.clock,
    required this.router,
  });

  final SettingsRepository settingsRepository;
  final rhythm.RhythmSession rhythmSession;
  final SystemClock clock;
  final ClockRhythmRouter router;
}

abstract interface class AppPlatformBootstrap {
  PlatformPresentationProfile get presentationProfile;

  AutoStartPort get recoveryAutoStart;

  PreferencesRepairStatePort get preferencesRepairState;

  Future<void> initializeBeforeRunApp();

  Future<AppPlatformServices> create(ClockRhythmPlatformContext context);

  Future<void> dispose();
}

final class ClockRhythmRuntime {
  ClockRhythmRuntime._({
    required this._container,
    required this._router,
    required this._databaseReady,
    required this._platformServices,
  });

  final ProviderContainer _container;
  final ClockRhythmRouter _router;
  final DatabaseReady _databaseReady;
  final AppPlatformServices _platformServices;
  bool _isDisposed = false;

  static Future<ClockRhythmRuntime> create({
    required DatabaseReady databaseReady,
    required AppPlatformServices platformServices,
    required DeviceSoundLocatorStore deviceSoundLocatorStore,
    required DraftStore draftStore,
    required BackupFilePort backupFile,
    required PortableBackupCodec backupCodec,
    SystemClock? systemClock,
    todo.TodoIdGenerator? todoIdGenerator,
    rhythm.LegacyCoexistenceWarning legacyCoexistenceWarning =
        const rhythm.NoLegacyCoexistenceWarning(),
  }) {
    return _create(
      databaseReady: databaseReady,
      presentationProfile: platformServices.presentationProfile,
      platformServicesFactory: (_) async => platformServices,
      deviceSoundLocatorStore: deviceSoundLocatorStore,
      draftStore: draftStore,
      backupFile: backupFile,
      backupCodec: backupCodec,
      systemClock: systemClock,
      todoIdGenerator: todoIdGenerator,
      legacyCoexistenceWarning: legacyCoexistenceWarning,
    );
  }

  static Future<ClockRhythmRuntime> createWithPlatformFactory({
    required DatabaseReady databaseReady,
    required PlatformPresentationProfile presentationProfile,
    required AppPlatformServicesFactory platformServicesFactory,
    required DeviceSoundLocatorStore deviceSoundLocatorStore,
    required DraftStore draftStore,
    required BackupFilePort backupFile,
    required PortableBackupCodec backupCodec,
    SystemClock? systemClock,
    todo.TodoIdGenerator? todoIdGenerator,
    rhythm.LegacyCoexistenceWarning legacyCoexistenceWarning =
        const rhythm.NoLegacyCoexistenceWarning(),
  }) {
    return _create(
      databaseReady: databaseReady,
      presentationProfile: presentationProfile,
      platformServicesFactory: platformServicesFactory,
      deviceSoundLocatorStore: deviceSoundLocatorStore,
      draftStore: draftStore,
      backupFile: backupFile,
      backupCodec: backupCodec,
      systemClock: systemClock,
      todoIdGenerator: todoIdGenerator,
      legacyCoexistenceWarning: legacyCoexistenceWarning,
    );
  }

  static Future<ClockRhythmRuntime> _create({
    required DatabaseReady databaseReady,
    required PlatformPresentationProfile presentationProfile,
    required AppPlatformServicesFactory platformServicesFactory,
    required DeviceSoundLocatorStore deviceSoundLocatorStore,
    required DraftStore draftStore,
    required BackupFilePort backupFile,
    required PortableBackupCodec backupCodec,
    required SystemClock? systemClock,
    required todo.TodoIdGenerator? todoIdGenerator,
    required rhythm.LegacyCoexistenceWarning legacyCoexistenceWarning,
  }) async {
    final SystemClock clock = systemClock ?? SystemClock();
    final DeviceSoundLocatorMutationCoordinator locatorMutation =
        DeviceSoundLocatorMutationCoordinator(deviceSoundLocatorStore);
    final DriftSettingsRepository settingsRepository = DriftSettingsRepository(
      databaseReady.database,
      deviceSoundLocatorStore: deviceSoundLocatorStore,
      deviceSoundLocatorMutation: locatorMutation,
    );
    final DriftTodoRepository todoRepository = DriftTodoRepository(
      databaseReady.database,
    );
    final UserPreferences initialPreferences = await settingsRepository.load();
    final rhythm.RhythmSession rhythmSession = rhythm.RhythmSession.idle(
      configuration: initialPreferences.rhythmConfiguration,
    );
    final ClockRhythmRouter router = ClockRhythmRouter(
      profile: presentationProfile,
      pages: _destinationPages(),
    );
    final AppPlatformServices platformServices;
    try {
      platformServices = await platformServicesFactory(
        ClockRhythmPlatformContext(
          settingsRepository: settingsRepository,
          rhythmSession: rhythmSession,
          clock: clock,
          router: router,
        ),
      );
    } on Object {
      router.dispose();
      await databaseReady.database.close();
      rethrow;
    }
    if (platformServices.presentationProfile != presentationProfile) {
      await platformServices.dispose();
      router.dispose();
      await databaseReady.database.close();
      throw StateError(
        'Platform services do not match the selected presentation profile.',
      );
    }

    final _InitialRhythmLoad initialRhythmLoad;
    try {
      initialRhythmLoad = await _restorePlatformRhythm(
        session: rhythmSession,
        platform: platformServices,
      );
    } on Object catch (error, stackTrace) {
      await _disposeFailedPlatformStartup(
        platformServices: platformServices,
        router: router,
        databaseReady: databaseReady,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
    final _RhythmUseCases rhythmUseCases = _createRhythmUseCases(
      session: rhythmSession,
      clock: clock,
      platform: platformServices,
      initialRhythmLoad: initialRhythmLoad,
    );
    final CoordinatingPreferencesChangedPort preferencesChanged =
        CoordinatingPreferencesChangedPort(
          rescheduleRhythm: rhythmUseCases.reschedule,
          refreshDeliveryPayload: platformServices.refreshDeliveryPayload,
          refreshSound: platformServices.refreshSound,
        );
    final PreferencesActions preferencesActions = _createPreferencesActions(
      settingsRepository: settingsRepository,
      draftStore: draftStore,
      preferencesChanged: preferencesChanged,
      platform: platformServices,
    );
    final TodoPresentationDependencies todoDependencies =
        _createTodoDependencies(
          repository: todoRepository,
          clock: clock,
          idGenerator:
              todoIdGenerator ?? SecureRandomTodoIdGenerator(now: clock.now),
        );

    late final ProviderContainer container;
    final ProviderDataImportRefreshAdapter importRefresh =
        ProviderDataImportRefreshAdapter(
          settingsRepository: settingsRepository,
          draftStore: draftStore,
          container: () => container,
          applyImportedPreferences: (UserPreferences preferences) async {
            rhythmSession.replaceConfiguration(
              preferences.rhythmConfiguration,
              observedAt: clock.now(),
            );
          },
        );
    final DataTransferActions dataTransferActions = _createDataTransferActions(
      settingsRepository: settingsRepository,
      todoRepository: todoRepository,
      backupFile: backupFile,
      backupCodec: backupCodec,
      clock: clock,
      replacement: _RepairTrackingBackupReplacementPort(
        delegate: DriftBackupReplacementAdapter(
          database: databaseReady.database,
          autoStart: platformServices.autoStart,
          deviceSoundLocatorStore: deviceSoundLocatorStore,
          deviceSoundLocatorMutation: locatorMutation,
        ),
        repairState: platformServices.preferencesRepairState,
      ),
      rhythmSafety: RhythmImportSafetyAdapter(
        session: rhythmSession,
        delivery: platformServices.rhythmDelivery,
        statusSink: platformServices.rhythmStatusSink,
        clock: clock,
        stopActiveAudio: platformServices.stopActiveAudio,
      ),
      importRefresh: importRefresh,
    );

    container = ProviderContainer(
      overrides: [
        preferencesActionsProvider.overrideWithValue(preferencesActions),
        preferencesPlatformCapabilitiesProvider.overrideWithValue(
          platformServices.preferencesCapabilities,
        ),
        deliveryPermissionActionsProvider.overrideWithValue(
          platformServices.deliveryPermissionActions,
        ),
        rhythmActionsProvider.overrideWithValue(rhythmUseCases.actions),
        legacyCoexistenceWarningProvider.overrideWithValue(
          legacyCoexistenceWarning,
        ),
        todoPresentationDependenciesProvider.overrideWithValue(
          todoDependencies,
        ),
        todoDateClockProvider.overrideWith((Ref ref) {
          final SystemTodoDateClock dateClock = SystemTodoDateClock(
            now: clock.now,
          );
          ref.onDispose(dateClock.dispose);
          return dateClock;
        }),
        dataTransferActionsProvider.overrideWithValue(dataTransferActions),
      ],
    );
    try {
      await platformServices.bindRhythmActions(rhythmUseCases.actions);
    } on Object {
      container.dispose();
      router.dispose();
      await platformServices.dispose();
      await databaseReady.database.close();
      rethrow;
    }
    return ClockRhythmRuntime._(
      container: container,
      router: router,
      databaseReady: databaseReady,
      platformServices: platformServices,
    );
  }

  Widget buildApp() {
    return UncontrolledProviderScope(
      container: _container,
      child: ClockRhythmRoot(router: _router.router),
    );
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _container.dispose();
    _router.dispose();
    await _platformServices.dispose();
    await _databaseReady.database.close();
  }

  static _RhythmUseCases _createRhythmUseCases({
    required rhythm.RhythmSession session,
    required SystemClock clock,
    required AppPlatformServices platform,
    required _InitialRhythmLoad initialRhythmLoad,
  }) {
    final rhythm.StartRhythm start = rhythm.StartRhythm(
      session: session,
      clock: clock,
      delivery: platform.rhythmDelivery,
      statusSink: platform.rhythmStatusSink,
    );
    final rhythm.PauseRhythm pause = rhythm.PauseRhythm(
      session: session,
      clock: clock,
      delivery: platform.rhythmDelivery,
      statusSink: platform.rhythmStatusSink,
    );
    final rhythm.ResumeRhythm resume = rhythm.ResumeRhythm(
      session: session,
      clock: clock,
      delivery: platform.rhythmDelivery,
      statusSink: platform.rhythmStatusSink,
    );
    final rhythm.StopRhythmForToday stopForToday = rhythm.StopRhythmForToday(
      session: session,
      clock: clock,
      delivery: platform.rhythmDelivery,
      statusSink: platform.rhythmStatusSink,
    );
    final rhythm.ReconcileRhythm reconcile = rhythm.ReconcileRhythm(
      session: session,
      clock: clock,
      delivery: platform.rhythmDelivery,
      statusSink: platform.rhythmStatusSink,
    );
    final rhythm.RescheduleRunningRhythm reschedule =
        rhythm.RescheduleRunningRhythm(
          session: session,
          clock: clock,
          delivery: platform.rhythmDelivery,
          statusSink: platform.rhythmStatusSink,
        );
    return _RhythmUseCases(
      actions: ApplicationRhythmActions(
        start: start,
        pause: pause,
        resume: resume,
        stopForToday: stopForToday,
        reconcile: reconcile,
        startCapability: platform.rhythmStartCapability,
        initialSnapshot: initialRhythmLoad.snapshot,
        initialRecoveryRequired: initialRhythmLoad.recoveryRequired,
      ),
      reschedule: reschedule,
    );
  }

  static Future<_InitialRhythmLoad> _restorePlatformRhythm({
    required rhythm.RhythmSession session,
    required AppPlatformServices platform,
  }) async {
    final rhythm.DeliveryRecoveryPort? recovery = platform.deliveryRecovery;
    if (recovery == null) {
      return const _InitialRhythmLoad();
    }
    final rhythm.DeliveryRecoveryStatus status = await recovery
        .auditForeground();
    switch (status.disposition) {
      case rhythm.DeliveryRecoveryDisposition.inactive:
        return const _InitialRhythmLoad();
      case rhythm.DeliveryRecoveryDisposition.running:
        session.start(status.configuration!);
        final rhythm.RhythmEvent? nextEvent = session.nextEventAfter(
          status.observedAt,
        );
        return _InitialRhythmLoad(
          snapshot: rhythm.RhythmStatusSnapshot.capture(
            session: session,
            observedAt: status.observedAt,
            nextEvent: nextEvent,
          ),
        );
      case rhythm.DeliveryRecoveryDisposition.needsUserRecovery:
        return _InitialRhythmLoad(
          snapshot: rhythm.RhythmStatusSnapshot.capture(
            session: session,
            observedAt: status.observedAt,
            nextEvent: null,
          ),
          recoveryRequired: true,
        );
    }
  }

  static Future<void> _disposeFailedPlatformStartup({
    required AppPlatformServices platformServices,
    required ClockRhythmRouter router,
    required DatabaseReady databaseReady,
  }) async {
    try {
      await platformServices.dispose();
    } on Object {
      // Preserve the startup failure that explains why no app was created.
    }
    router.dispose();
    try {
      await databaseReady.database.close();
    } on Object {
      // Preserve the startup failure that explains why no app was created.
    }
  }

  static PreferencesActions _createPreferencesActions({
    required SettingsRepository settingsRepository,
    required DraftStore draftStore,
    required PreferencesChangedPort preferencesChanged,
    required AppPlatformServices platform,
  }) {
    final GetPreferences getPreferences = GetPreferences(settingsRepository);
    final LoadRhythmSettingsDraft loadDraft = LoadRhythmSettingsDraft(
      settingsRepository: settingsRepository,
      draftStore: draftStore,
    );
    final StoreRhythmSettingsDraft storeDraft = StoreRhythmSettingsDraft(
      draftStore,
    );
    final DiscardRhythmSettingsDraft discardDraft = DiscardRhythmSettingsDraft(
      settingsRepository: settingsRepository,
      draftStore: draftStore,
    );
    return ApplicationPreferencesActions(
      getPreferences: getPreferences,
      loadDraft: loadDraft,
      storeDraft: storeDraft,
      discardDraft: discardDraft,
      saveRhythm: SaveRhythmSettings(
        settingsRepository: settingsRepository,
        autoStart: platform.autoStart,
        preferencesChanged: preferencesChanged,
        draftStore: draftStore,
      ),
      changeLanguage: ChangeLanguage(
        settingsRepository: settingsRepository,
        preferencesChanged: preferencesChanged,
      ),
      changeTheme: ChangeTheme(
        settingsRepository: settingsRepository,
        preferencesChanged: preferencesChanged,
      ),
      changeSound: ChangeNotificationSound(
        settingsRepository: settingsRepository,
        soundFilePort: platform.notificationSoundFile,
        soundPreview: platform.soundPreview,
        preferencesChanged: preferencesChanged,
      ),
      changeVolume: ChangeVolume(
        settingsRepository: settingsRepository,
        preferencesChanged: preferencesChanged,
      ),
      toggleMute: ToggleMute(
        settingsRepository: settingsRepository,
        soundPreview: platform.soundPreview,
        preferencesChanged: preferencesChanged,
        unmuteBehavior:
            platform.preferencesCapabilities.kind ==
                PreferencesPlatformKind.windows
            ? UnmuteSoundBehavior.restorePreviousSelection
            : UnmuteSoundBehavior.bundledDefault,
      ),
      previewSound: PreviewNotificationSound(
        settingsRepository: settingsRepository,
        soundPreview: platform.soundPreview,
      ),
      stopSoundPreview: StopNotificationSoundPreview(platform.soundPreview),
      repairEffect: RepairPreferencesEffect(
        settingsRepository: settingsRepository,
        preferencesChanged: preferencesChanged,
      ),
      repairAutoStart: RepairAutoStart(
        settingsRepository: settingsRepository,
        autoStart: platform.autoStart,
      ),
      repairState: platform.preferencesRepairState,
    );
  }

  static TodoPresentationDependencies _createTodoDependencies({
    required todo.TodoRepository repository,
    required SystemClock clock,
    required todo.TodoIdGenerator idGenerator,
  }) {
    return TodoPresentationDependencies(
      createTodo: todo.CreateTodo(
        repository: repository,
        idGenerator: idGenerator,
        clock: clock,
      ),
      updateTodo: todo.UpdateTodo(repository: repository, clock: clock),
      renameTodo: todo.RenameTodo(repository: repository, clock: clock),
      toggleTodoCompletion: todo.ToggleTodoCompletion(
        repository: repository,
        clock: clock,
      ),
      reorderTodos: todo.ReorderTodos(repository: repository, clock: clock),
      deleteTodo: todo.DeleteTodo(repository: repository),
      listTodosForDate: todo.ListTodosForDate(repository: repository),
      listMonthSummary: todo.ListMonthSummary(repository: repository),
    );
  }

  static DataTransferActions _createDataTransferActions({
    required SettingsRepository settingsRepository,
    required todo.TodoRepository todoRepository,
    required BackupFilePort backupFile,
    required PortableBackupCodec backupCodec,
    required BackupClock clock,
    required BackupReplacementPort replacement,
    required RhythmSafetyPort rhythmSafety,
    required DataImportRefreshPort importRefresh,
  }) {
    final GetPreferences getPreferences = GetPreferences(settingsRepository);
    return ApplicationDataTransferActions(
      exportBackup: ExportPortableBackup(
        getPreferences: getPreferences,
        exportTodos: todo.ExportTodoSnapshots(repository: todoRepository),
        backupFile: backupFile,
        codec: backupCodec,
        clock: clock,
      ),
      prepareImport: PrepareBackupImport(
        backupFile: backupFile,
        codec: backupCodec,
        getPreferences: getPreferences,
      ),
      confirmImport: ConfirmBackupImport(
        rhythmSafety: rhythmSafety,
        replacement: replacement,
      ),
      refresh: importRefresh,
    );
  }

  static AppDestinationPages _destinationPages() {
    return AppDestinationPages(
      clock: (BuildContext context) => ClockPage(
        todayTodo: const TodayTodoPanel(),
        onOpenSettings: () => context.go(MainDestination.settings.location),
      ),
      calendar: (BuildContext context, AppCalendarDate? selectedDate) {
        return CalendarPage(
          initialSelectedDate: selectedDate == null
              ? null
              : LocalCalendarDate.parse(selectedDate.iso8601),
          onSelectedDateChanged: (LocalCalendarDate date) {
            context.go(
              AppRoute.calendar(AppCalendarDate.parse(date.text)).location,
            );
          },
        );
      },
      data: (_) => const DataPage(),
      theme: (_) => const ThemePage(),
      settings: (_) => const PreferencesPage(),
    );
  }
}

final class _RhythmUseCases {
  const _RhythmUseCases({required this.actions, required this.reschedule});

  final RhythmActions actions;
  final rhythm.RescheduleRunningRhythm reschedule;
}

final class _InitialRhythmLoad {
  const _InitialRhythmLoad({this.snapshot, this.recoveryRequired = false});

  final rhythm.RhythmStatusSnapshot? snapshot;
  final bool recoveryRequired;
}

final class _RepairTrackingBackupReplacementPort
    implements BackupReplacementPort {
  const _RepairTrackingBackupReplacementPort({
    required this.delegate,
    required this.repairState,
  });

  final BackupReplacementPort delegate;
  final PreferencesRepairStatePort repairState;

  @override
  Future<BackupReplacementResult> replaceAll({
    required UserPreferences preferences,
    required List<todo.Todo> todos,
  }) async {
    final BackupReplacementResult result = await delegate.replaceAll(
      preferences: preferences,
      todos: todos,
    );
    repairState.recordCommandResult(
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.autoStart},
      reported: result.autoStartRepairRequired
          ? const <PreferencesRepairNeed>{PreferencesRepairNeed.autoStart}
          : const <PreferencesRepairNeed>{},
    );
    return result;
  }
}
