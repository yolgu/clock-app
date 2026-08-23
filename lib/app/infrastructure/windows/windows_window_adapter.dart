import 'dart:async';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../application/ports/window_port.dart';
import 'local_app_data_window_state_store.dart';
import 'windows_window_state.dart';

final class WindowsLifecycleConfiguration {
  const WindowsLifecycleConfiguration({
    required this.applicationIdentity,
    required this.startsHidden,
  });

  final String applicationIdentity;
  final bool startsHidden;
}

abstract interface class WindowsLifecycleHost {
  Future<WindowsLifecycleConfiguration> loadConfiguration();

  Future<WindowsWindowPlacement> captureNormalWindowPlacement();

  Future<WindowsWindowPlacement> restoreNormalWindowPlacement(
    WindowsWindowPlacement placement,
  );

  Future<void> setRestoreMaximized(bool maximized);

  Future<void> activateWindow();

  Future<void> requestApplicationExit();
}

abstract interface class WindowsWindowEventHandler {
  void onWindowBoundsChanged();

  void onWindowMaximized();

  void onWindowRestored();
}

abstract interface class WindowsWindowPlugin {
  Future<void> initialize();

  Future<void> setMinimumSize({required double width, required double height});

  Future<bool> isMaximized();

  Future<void> hide();

  void setEventHandler(WindowsWindowEventHandler? handler);
}

final class WindowsWindowAdapter
    implements WindowPort, WindowsWindowEventHandler {
  WindowsWindowAdapter({
    required this.expectedApplicationIdentity,
    WindowsWindowPlugin? windowPlugin,
    WindowsLifecycleHost? lifecycleHost,
    WindowsWindowStateStore? stateStore,
  }) : _windowPlugin = windowPlugin ?? WindowManagerWindowsWindowPlugin(),
       _lifecycleHost = lifecycleHost ?? MethodChannelWindowsLifecycleHost(),
       _stateStore = stateStore ?? LocalAppDataWindowStateStore();

  static const double initialWidth = 920;
  static const double initialHeight = 680;
  static const double minimumWidth = 720;
  static const double minimumHeight = 560;

  final String expectedApplicationIdentity;
  final WindowsWindowPlugin _windowPlugin;
  final WindowsLifecycleHost _lifecycleHost;
  final WindowsWindowStateStore _stateStore;

  bool _initialized = false;
  bool _disposed = false;
  bool _restoreMaximized = false;
  String? _applicationIdentity;
  WindowsWindowPlacement? _normalPlacement;
  Future<void> _pendingStateWork = Future<void>.value();
  Object? _latestStateFailure;

  Object? get latestStateFailure => _latestStateFailure;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (_disposed) {
      throw StateError(
        'A disposed WindowsWindowAdapter cannot be initialized.',
      );
    }

    await _windowPlugin.initialize();
    final WindowsLifecycleConfiguration configuration = await _lifecycleHost
        .loadConfiguration();
    if (configuration.applicationIdentity != expectedApplicationIdentity) {
      throw StateError(
        'Windows native identity ${configuration.applicationIdentity} '
        'does not match the Dart flavor identity '
        '$expectedApplicationIdentity.',
      );
    }
    _applicationIdentity = configuration.applicationIdentity;
    await _windowPlugin.setMinimumSize(
      width: minimumWidth,
      height: minimumHeight,
    );

    final WindowsWindowState? storedState = await _loadStoredState(
      configuration.applicationIdentity,
    );
    final WindowsWindowPlacement restoredPlacement;
    if (storedState == null) {
      restoredPlacement = await _lifecycleHost.captureNormalWindowPlacement();
    } else {
      restoredPlacement = await _lifecycleHost.restoreNormalWindowPlacement(
        storedState.placement,
      );
    }
    _normalPlacement = restoredPlacement;
    _restoreMaximized = storedState?.maximized ?? false;

    await _lifecycleHost.setRestoreMaximized(_restoreMaximized);
    if (storedState != null && restoredPlacement != storedState.placement) {
      try {
        await _stateStore.save(
          applicationIdentity: configuration.applicationIdentity,
          state: WindowsWindowState(
            placement: restoredPlacement,
            maximized: _restoreMaximized,
          ),
        );
      } on Object catch (error) {
        _latestStateFailure = error;
      }
    }

    _windowPlugin.setEventHandler(this);
    _initialized = true;
  }

  @override
  Future<void> open() async {
    _requireInitialized();
    await _lifecycleHost.activateWindow();
  }

  @override
  Future<void> hide() async {
    _requireInitialized();
    await flushPendingState();
    await _captureStateBeforeLifecycleEffect();
    await _windowPlugin.hide();
  }

  @override
  Future<void> requestApplicationExit() async {
    _requireInitialized();
    await flushPendingState();
    await _captureStateBeforeLifecycleEffect();
    await _lifecycleHost.requestApplicationExit();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _windowPlugin.setEventHandler(null);
    await flushPendingState();
  }

  @override
  void onWindowBoundsChanged() {
    _scheduleStateWork(_captureAndSaveNormalBounds);
  }

  @override
  void onWindowMaximized() {
    _restoreMaximized = true;
    _scheduleStateWork(() async {
      await _lifecycleHost.setRestoreMaximized(true);
      await _saveKnownState();
    });
  }

  @override
  void onWindowRestored() {
    _restoreMaximized = false;
    _scheduleStateWork(() async {
      await _lifecycleHost.setRestoreMaximized(false);
      await _captureAndSaveNormalBounds();
    });
  }

  Future<void> flushPendingState() async {
    await _pendingStateWork;
  }

  void _scheduleStateWork(Future<void> Function() work) {
    if (!_initialized || _disposed) {
      return;
    }
    _pendingStateWork = _pendingStateWork.then((_) => work()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _latestStateFailure = error;
    });
  }

  Future<void> _captureAndSaveNormalBounds() async {
    if (await _windowPlugin.isMaximized()) {
      await _saveKnownState();
      return;
    }
    final WindowsWindowPlacement placement = await _lifecycleHost
        .captureNormalWindowPlacement();
    if (placement.isValid) {
      _normalPlacement = placement;
    }
    await _saveKnownState();
  }

  Future<WindowsWindowState?> _loadStoredState(
    String applicationIdentity,
  ) async {
    try {
      return await _stateStore.load(applicationIdentity: applicationIdentity);
    } on Object catch (error) {
      _latestStateFailure = error;
      return null;
    }
  }

  Future<void> _captureStateBeforeLifecycleEffect() async {
    try {
      await _captureAndSaveNormalBounds();
    } on Object catch (error) {
      _latestStateFailure = error;
    }
  }

  Future<void> _saveKnownState() async {
    final String? applicationIdentity = _applicationIdentity;
    final WindowsWindowPlacement? normalPlacement = _normalPlacement;
    if (applicationIdentity == null || normalPlacement == null) {
      return;
    }
    await _stateStore.save(
      applicationIdentity: applicationIdentity,
      state: WindowsWindowState(
        placement: normalPlacement,
        maximized: _restoreMaximized,
      ),
    );
  }

  void _requireInitialized() {
    if (!_initialized || _disposed) {
      throw StateError('WindowsWindowAdapter is not active.');
    }
  }
}

final class MethodChannelWindowsLifecycleHost implements WindowsLifecycleHost {
  MethodChannelWindowsLifecycleHost({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'clock_rhythm/windows_window';

  final MethodChannel _channel;

  @override
  Future<WindowsLifecycleConfiguration> loadConfiguration() async {
    final Object? response = await _channel.invokeMethod<Object?>(
      'getConfiguration',
    );
    final Map<Object?, Object?> value = _requireMap(
      response,
      'Windows lifecycle configuration',
    );
    _requireExactKeys(value, const <String>{
      'applicationIdentity',
      'startsHidden',
    });
    final Object? applicationIdentity = value['applicationIdentity'];
    final Object? startsHidden = value['startsHidden'];
    if (applicationIdentity is! String ||
        !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(applicationIdentity) ||
        startsHidden is! bool) {
      throw const FormatException('Invalid Windows lifecycle configuration');
    }
    return WindowsLifecycleConfiguration(
      applicationIdentity: applicationIdentity,
      startsHidden: startsHidden,
    );
  }

  @override
  Future<WindowsWindowPlacement> captureNormalWindowPlacement() async {
    final Object? response = await _channel.invokeMethod<Object?>(
      'captureNormalWindowPlacement',
    );
    return _placement(response);
  }

  @override
  Future<WindowsWindowPlacement> restoreNormalWindowPlacement(
    WindowsWindowPlacement placement,
  ) async {
    if (!placement.isValid) {
      throw ArgumentError.value(placement, 'placement', 'must be valid');
    }
    final Object? response = await _channel
        .invokeMethod<Object?>('restoreNormalWindowPlacement', <String, int>{
          'left': placement.bounds.left,
          'top': placement.bounds.top,
          'width': placement.bounds.width,
          'height': placement.bounds.height,
          'sourceDpi': placement.dpi,
        });
    return _placement(response);
  }

  @override
  Future<void> setRestoreMaximized(bool maximized) async {
    await _channel.invokeMethod<void>('setRestoreMaximized', <String, bool>{
      'maximized': maximized,
    });
  }

  @override
  Future<void> activateWindow() async {
    await _channel.invokeMethod<void>('activateWindow');
  }

  @override
  Future<void> requestApplicationExit() async {
    await _channel.invokeMethod<void>('requestApplicationExit');
  }

  Map<Object?, Object?> _requireMap(Object? value, String name) {
    if (value is! Map<Object?, Object?>) {
      throw FormatException('$name must be a map');
    }
    return value;
  }

  void _requireExactKeys(Map<Object?, Object?> value, Set<String> expected) {
    if (value.length != expected.length ||
        !value.keys.every(
          (Object? key) => key is String && expected.contains(key),
        )) {
      throw const FormatException('Unexpected Windows native response keys');
    }
  }

  WindowsWindowPlacement _placement(Object? response) {
    final Map<Object?, Object?> value = _requireMap(
      response,
      'Windows physical placement',
    );
    _requireExactKeys(value, const <String>{
      'left',
      'top',
      'width',
      'height',
      'dpi',
    });
    final WindowsWindowPlacement placement = WindowsWindowPlacement(
      bounds: WindowsWindowBounds(
        left: _integer(value['left']),
        top: _integer(value['top']),
        width: _integer(value['width']),
        height: _integer(value['height']),
      ),
      dpi: _integer(value['dpi']),
    );
    if (!placement.isValid) {
      throw const FormatException('Invalid Windows physical placement');
    }
    return placement;
  }

  int _integer(Object? value) {
    if (value is! int) {
      throw const FormatException('Windows placement must use integers');
    }
    return value;
  }
}

final class WindowManagerWindowsWindowPlugin implements WindowsWindowPlugin {
  WindowManagerWindowsWindowPlugin({WindowManager? manager})
    : _manager = manager ?? windowManager;

  final WindowManager _manager;
  late final _WindowManagerEventBridge _eventBridge =
      _WindowManagerEventBridge();
  bool _listening = false;

  @override
  Future<void> initialize() {
    return _manager.ensureInitialized();
  }

  @override
  Future<void> setMinimumSize({required double width, required double height}) {
    return _manager.setMinimumSize(Size(width, height));
  }

  @override
  Future<bool> isMaximized() {
    return _manager.isMaximized();
  }

  @override
  Future<void> hide() {
    return _manager.hide();
  }

  @override
  void setEventHandler(WindowsWindowEventHandler? handler) {
    _eventBridge.handler = handler;
    if (handler != null && !_listening) {
      _manager.addListener(_eventBridge);
      _listening = true;
      return;
    }
    if (handler == null && _listening) {
      _manager.removeListener(_eventBridge);
      _listening = false;
    }
  }
}

final class _WindowManagerEventBridge with WindowListener {
  WindowsWindowEventHandler? handler;

  @override
  void onWindowMoved() {
    handler?.onWindowBoundsChanged();
  }

  @override
  void onWindowResized() {
    handler?.onWindowBoundsChanged();
  }

  @override
  void onWindowMaximize() {
    handler?.onWindowMaximized();
  }

  @override
  void onWindowUnmaximize() {
    handler?.onWindowRestored();
  }
}
