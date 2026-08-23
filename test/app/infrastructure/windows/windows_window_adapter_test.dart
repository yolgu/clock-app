import 'package:clock_rhythm/app/infrastructure/windows/windows_window_adapter.dart';
import 'package:clock_rhythm/app/infrastructure/windows/windows_window_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowsWindowAdapter', () {
    test(
      'restores native-clamped physical placement and maximized state',
      () async {
        final FakeWindowsWindowPlugin plugin = FakeWindowsWindowPlugin();
        final FakeWindowsLifecycleHost host = FakeWindowsLifecycleHost()
          ..restoredPlacement = const WindowsWindowPlacement(
            bounds: WindowsWindowBounds(
              left: 920,
              top: 340,
              width: 1000,
              height: 700,
            ),
            dpi: 96,
          );
        final FakeWindowsWindowStateStore store = FakeWindowsWindowStateStore(
          const WindowsWindowState(
            placement: WindowsWindowPlacement(
              bounds: WindowsWindowBounds(
                left: 6000,
                top: 4000,
                width: 1500,
                height: 1050,
              ),
              dpi: 144,
            ),
            maximized: true,
          ),
        );
        final WindowsWindowAdapter adapter = WindowsWindowAdapter(
          windowPlugin: plugin,
          lifecycleHost: host,
          stateStore: store,
        );

        await adapter.initialize();

        expect(plugin.initialized, isTrue);
        expect(plugin.minimumWidth, WindowsWindowAdapter.minimumWidth);
        expect(plugin.minimumHeight, WindowsWindowAdapter.minimumHeight);
        expect(host.restoreRequests.single, store.initialState!.placement);
        expect(host.restoreMaximized, isTrue);
        expect(host.activationRequests, 0);
        expect(store.identityReads, <String>['dev.wndls.clockrhythm']);
        expect(store.savedStates.single.placement, host.restoredPlacement);
        expect(store.savedStates.single.maximized, isTrue);
      },
    );

    test(
      'captures the native physical first placement when state is absent',
      () async {
        final FakeWindowsLifecycleHost host = FakeWindowsLifecycleHost();
        final WindowsWindowAdapter adapter = WindowsWindowAdapter(
          windowPlugin: FakeWindowsWindowPlugin(),
          lifecycleHost: host,
          stateStore: FakeWindowsWindowStateStore(),
        );

        await adapter.initialize();

        expect(host.captureRequests, 1);
        expect(host.restoreRequests, isEmpty);
        expect(host.restoreMaximized, isFalse);
      },
    );

    test(
      'persists physical placement and delegates open, hide, and exit',
      () async {
        final FakeWindowsWindowPlugin plugin = FakeWindowsWindowPlugin();
        final FakeWindowsLifecycleHost host = FakeWindowsLifecycleHost();
        final FakeWindowsWindowStateStore store = FakeWindowsWindowStateStore();
        final WindowsWindowAdapter adapter = WindowsWindowAdapter(
          windowPlugin: plugin,
          lifecycleHost: host,
          stateStore: store,
        );
        await adapter.initialize();
        host.capturedPlacement = const WindowsWindowPlacement(
          bounds: WindowsWindowBounds(
            left: 75,
            top: 105,
            width: 1470,
            height: 1080,
          ),
          dpi: 144,
        );

        await adapter.hide();
        await adapter.open();
        await adapter.requestApplicationExit();

        expect(plugin.hideRequests, 1);
        expect(host.activationRequests, 1);
        expect(host.exitRequests, 1);
        expect(store.savedStates.last.placement, host.capturedPlacement);
        expect(store.savedStates.last.maximized, isFalse);
      },
    );

    test(
      'maximized state preserves the last normal physical placement',
      () async {
        final FakeWindowsWindowPlugin plugin = FakeWindowsWindowPlugin();
        final FakeWindowsLifecycleHost host = FakeWindowsLifecycleHost();
        final FakeWindowsWindowStateStore store = FakeWindowsWindowStateStore();
        final WindowsWindowAdapter adapter = WindowsWindowAdapter(
          windowPlugin: plugin,
          lifecycleHost: host,
          stateStore: store,
        );
        await adapter.initialize();
        final WindowsWindowPlacement normalPlacement = host.capturedPlacement;

        plugin.maximized = true;
        plugin.emitMaximized();
        await adapter.flushPendingState();

        expect(host.restoreMaximized, isTrue);
        expect(store.savedStates.last.placement, normalPlacement);
        expect(store.savedStates.last.maximized, isTrue);

        plugin.maximized = false;
        host.capturedPlacement = const WindowsWindowPlacement(
          bounds: WindowsWindowBounds(
            left: 180,
            top: 135,
            width: 1440,
            height: 1050,
          ),
          dpi: 144,
        );
        plugin.emitRestored();
        await adapter.flushPendingState();

        expect(host.restoreMaximized, isFalse);
        expect(store.savedStates.last.placement, host.capturedPlacement);
        expect(store.savedStates.last.maximized, isFalse);
      },
    );

    test('removes plugin callbacks during idempotent disposal', () async {
      final FakeWindowsWindowPlugin plugin = FakeWindowsWindowPlugin();
      final WindowsWindowAdapter adapter = WindowsWindowAdapter(
        windowPlugin: plugin,
        lifecycleHost: FakeWindowsLifecycleHost(),
        stateStore: FakeWindowsWindowStateStore(),
      );
      await adapter.initialize();

      await adapter.dispose();
      await adapter.dispose();

      expect(plugin.eventHandler, isNull);
    });

    test(
      'noncritical state failure cannot block hide or explicit exit',
      () async {
        final FakeWindowsWindowPlugin plugin = FakeWindowsWindowPlugin();
        final FakeWindowsLifecycleHost host = FakeWindowsLifecycleHost();
        final FakeWindowsWindowStateStore store = FakeWindowsWindowStateStore()
          ..saveFailure = StateError('device state unavailable');
        final WindowsWindowAdapter adapter = WindowsWindowAdapter(
          windowPlugin: plugin,
          lifecycleHost: host,
          stateStore: store,
        );
        await adapter.initialize();

        await adapter.hide();
        await adapter.requestApplicationExit();

        expect(plugin.hideRequests, 1);
        expect(host.exitRequests, 1);
        expect(adapter.latestStateFailure, isA<StateError>());
      },
    );

    test(
      'noncritical state read failure falls back to native placement',
      () async {
        final FakeWindowsLifecycleHost host = FakeWindowsLifecycleHost();
        final FakeWindowsWindowStateStore store = FakeWindowsWindowStateStore()
          ..loadFailure = StateError('device state unreadable');
        final WindowsWindowAdapter adapter = WindowsWindowAdapter(
          windowPlugin: FakeWindowsWindowPlugin(),
          lifecycleHost: host,
          stateStore: store,
        );

        await adapter.initialize();

        expect(host.captureRequests, 1);
        expect(adapter.latestStateFailure, isA<StateError>());
      },
    );
  });

  test('method channel maps physical capture and restore contracts', () async {
    const MethodChannel channel = MethodChannel(
      'clock_rhythm/windows_window_test',
    );
    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return switch (call.method) {
            'getConfiguration' => <String, Object>{
              'applicationIdentity': 'dev.wndls.clockrhythm.beta',
              'startsHidden': true,
            },
            'captureNormalWindowPlacement' => <String, int>{
              'left': 10,
              'top': 10,
              'width': 920,
              'height': 680,
              'dpi': 96,
            },
            'restoreNormalWindowPlacement' => <String, int>{
              'left': 1920,
              'top': 0,
              'width': 1380,
              'height': 1020,
              'dpi': 144,
            },
            'setRestoreMaximized' ||
            'activateWindow' ||
            'requestApplicationExit' => null,
            _ => throw MissingPluginException(call.method),
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final MethodChannelWindowsLifecycleHost host =
        MethodChannelWindowsLifecycleHost(channel: channel);

    final WindowsLifecycleConfiguration configuration = await host
        .loadConfiguration();
    final WindowsWindowPlacement captured = await host
        .captureNormalWindowPlacement();
    final WindowsWindowPlacement restored = await host
        .restoreNormalWindowPlacement(captured);
    await host.setRestoreMaximized(true);
    await host.activateWindow();
    await host.requestApplicationExit();

    expect(configuration.applicationIdentity, 'dev.wndls.clockrhythm.beta');
    expect(configuration.startsHidden, isTrue);
    expect(captured.dpi, 96);
    expect(restored.dpi, 144);
    expect(calls[2].arguments, <String, int>{
      'left': 10,
      'top': 10,
      'width': 920,
      'height': 680,
      'sourceDpi': 96,
    });
    expect(calls[3].arguments, <String, bool>{'maximized': true});
  });
}

final class FakeWindowsWindowPlugin implements WindowsWindowPlugin {
  bool initialized = false;
  bool maximized = false;
  double? minimumWidth;
  double? minimumHeight;
  int hideRequests = 0;
  WindowsWindowEventHandler? eventHandler;

  void emitMaximized() {
    eventHandler?.onWindowMaximized();
  }

  void emitRestored() {
    eventHandler?.onWindowRestored();
  }

  @override
  Future<void> hide() async {
    hideRequests += 1;
  }

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> isMaximized() async => maximized;

  @override
  void setEventHandler(WindowsWindowEventHandler? handler) {
    eventHandler = handler;
  }

  @override
  Future<void> setMinimumSize({
    required double width,
    required double height,
  }) async {
    minimumWidth = width;
    minimumHeight = height;
  }
}

final class FakeWindowsLifecycleHost implements WindowsLifecycleHost {
  WindowsWindowPlacement capturedPlacement = const WindowsWindowPlacement(
    bounds: WindowsWindowBounds(left: 10, top: 10, width: 920, height: 680),
    dpi: 96,
  );
  WindowsWindowPlacement? restoredPlacement;
  final List<WindowsWindowPlacement> restoreRequests =
      <WindowsWindowPlacement>[];
  bool? restoreMaximized;
  int captureRequests = 0;
  int activationRequests = 0;
  int exitRequests = 0;

  @override
  Future<void> activateWindow() async {
    activationRequests += 1;
  }

  @override
  Future<WindowsWindowPlacement> captureNormalWindowPlacement() async {
    captureRequests += 1;
    return capturedPlacement;
  }

  @override
  Future<WindowsLifecycleConfiguration> loadConfiguration() async {
    return const WindowsLifecycleConfiguration(
      applicationIdentity: 'dev.wndls.clockrhythm',
      startsHidden: false,
    );
  }

  @override
  Future<void> requestApplicationExit() async {
    exitRequests += 1;
  }

  @override
  Future<WindowsWindowPlacement> restoreNormalWindowPlacement(
    WindowsWindowPlacement placement,
  ) async {
    restoreRequests.add(placement);
    return restoredPlacement ?? placement;
  }

  @override
  Future<void> setRestoreMaximized(bool maximized) async {
    restoreMaximized = maximized;
  }
}

final class FakeWindowsWindowStateStore implements WindowsWindowStateStore {
  FakeWindowsWindowStateStore([this.initialState]) : state = initialState;

  final WindowsWindowState? initialState;
  WindowsWindowState? state;
  Object? loadFailure;
  Object? saveFailure;
  final List<String> identityReads = <String>[];
  final List<WindowsWindowState> savedStates = <WindowsWindowState>[];

  @override
  Future<WindowsWindowState?> load({
    required String applicationIdentity,
  }) async {
    identityReads.add(applicationIdentity);
    final Object? failure = loadFailure;
    if (failure != null) {
      throw failure;
    }
    return state;
  }

  @override
  Future<void> save({
    required String applicationIdentity,
    required WindowsWindowState state,
  }) async {
    final Object? failure = saveFailure;
    if (failure != null) {
      throw failure;
    }
    this.state = state;
    savedStates.add(state);
  }
}
