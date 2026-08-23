import 'package:tray_manager/tray_manager.dart';

import '../../domain/rhythm_session.dart';

enum WindowsTrayCommand { open, pause, resume, stopForToday, quit }

enum WindowsTrayIconGesture { primary, secondary }

typedef WindowsTrayCommandCallback = void Function(WindowsTrayCommand command);
typedef WindowsTraySelectionCallback =
    void Function(WindowsTrayCommand command);
typedef WindowsTrayIconGestureCallback =
    void Function(WindowsTrayIconGesture gesture);

final class WindowsTrayLabels {
  const WindowsTrayLabels({
    required this.open,
    required this.pause,
    required this.resume,
    required this.stopForToday,
    required this.quit,
  });

  final String open;
  final String pause;
  final String resume;
  final String stopForToday;
  final String quit;
}

final class WindowsTrayMenuEntry {
  const WindowsTrayMenuEntry({
    required this.command,
    required this.label,
    required this.enabled,
  });

  final WindowsTrayCommand command;
  final String label;
  final bool enabled;

  @override
  bool operator ==(Object other) {
    return other is WindowsTrayMenuEntry &&
        command == other.command &&
        label == other.label &&
        enabled == other.enabled;
  }

  @override
  int get hashCode => Object.hash(command, label, enabled);
}

abstract interface class WindowsTrayPlugin {
  Future<void> initialize({
    required String iconAssetPath,
    required String toolTip,
    required WindowsTraySelectionCallback onSelected,
    required WindowsTrayIconGestureCallback onIconGesture,
  });

  Future<void> replaceMenu(List<WindowsTrayMenuEntry> entries);

  Future<void> popUpContextMenu();

  Future<void> dispose();
}

final class WindowsTrayAdapter {
  WindowsTrayAdapter({
    required this.onCommand,
    WindowsTrayPlugin? plugin,
    this.iconAssetPath = 'windows/runner/resources/app_icon.ico',
    this.toolTip = 'Clock Rhythm',
  }) : _plugin = plugin ?? TrayManagerWindowsTrayPlugin();

  final WindowsTrayCommandCallback onCommand;
  final WindowsTrayPlugin _plugin;
  final String iconAssetPath;
  final String toolTip;

  Set<WindowsTrayCommand> _enabledCommands = <WindowsTrayCommand>{};
  bool _initialized = false;
  bool _disposed = false;
  bool _acceptingIconGestures = false;
  Future<void> _pendingPluginWork = Future<void>.value();
  Object? _latestPluginFailure;

  Object? get latestPluginFailure => _latestPluginFailure;

  Future<void> initialize({
    required WindowsTrayLabels labels,
    required RhythmSessionStatus status,
  }) async {
    if (_initialized) {
      throw StateError('WindowsTrayAdapter is already initialized.');
    }
    if (_disposed) {
      throw StateError('A disposed WindowsTrayAdapter cannot be initialized.');
    }
    await _plugin.initialize(
      iconAssetPath: iconAssetPath,
      toolTip: toolTip,
      onSelected: _handleSelection,
      onIconGesture: _handleIconGesture,
    );
    try {
      await _replaceMenu(labels: labels, status: status);
    } on Object {
      await _plugin.dispose();
      rethrow;
    }
    _initialized = true;
    _acceptingIconGestures = true;
  }

  Future<void> update({
    required WindowsTrayLabels labels,
    required RhythmSessionStatus status,
  }) async {
    _requireActive();
    await _replaceMenu(labels: labels, status: status);
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _acceptingIconGestures = false;
    _enabledCommands = <WindowsTrayCommand>{};
    await flushPendingPluginWork();
    if (_initialized) {
      await _plugin.dispose();
    }
    _disposed = true;
  }

  Future<void> flushPendingPluginWork() async {
    await _pendingPluginWork;
  }

  Future<void> _replaceMenu({
    required WindowsTrayLabels labels,
    required RhythmSessionStatus status,
  }) async {
    final List<WindowsTrayMenuEntry> entries = _entriesFor(
      labels: labels,
      status: status,
    );
    await _plugin.replaceMenu(entries);
    _enabledCommands = entries
        .where((WindowsTrayMenuEntry entry) => entry.enabled)
        .map((WindowsTrayMenuEntry entry) => entry.command)
        .toSet();
  }

  List<WindowsTrayMenuEntry> _entriesFor({
    required WindowsTrayLabels labels,
    required RhythmSessionStatus status,
  }) {
    final bool canPause = status == RhythmSessionStatus.running;
    final bool canResume = status == RhythmSessionStatus.paused;
    final bool canStop =
        status == RhythmSessionStatus.running ||
        status == RhythmSessionStatus.paused;
    return <WindowsTrayMenuEntry>[
      WindowsTrayMenuEntry(
        command: WindowsTrayCommand.open,
        label: labels.open,
        enabled: true,
      ),
      WindowsTrayMenuEntry(
        command: WindowsTrayCommand.pause,
        label: labels.pause,
        enabled: canPause,
      ),
      WindowsTrayMenuEntry(
        command: WindowsTrayCommand.resume,
        label: labels.resume,
        enabled: canResume,
      ),
      WindowsTrayMenuEntry(
        command: WindowsTrayCommand.stopForToday,
        label: labels.stopForToday,
        enabled: canStop,
      ),
      WindowsTrayMenuEntry(
        command: WindowsTrayCommand.quit,
        label: labels.quit,
        enabled: true,
      ),
    ];
  }

  void _handleSelection(WindowsTrayCommand command) {
    if (!_disposed && _enabledCommands.contains(command)) {
      onCommand(command);
    }
  }

  void _handleIconGesture(WindowsTrayIconGesture gesture) {
    if (!_acceptingIconGestures || _disposed) {
      return;
    }
    _pendingPluginWork = _pendingPluginWork
        .then((_) => _plugin.popUpContextMenu())
        .catchError((Object error, StackTrace stackTrace) {
          _latestPluginFailure = error;
        });
  }

  void _requireActive() {
    if (!_initialized || _disposed) {
      throw StateError('WindowsTrayAdapter is not active.');
    }
  }
}

final class TrayManagerWindowsTrayPlugin implements WindowsTrayPlugin {
  TrayManagerWindowsTrayPlugin({TrayManager? manager})
    : _manager = manager ?? trayManager;

  final TrayManager _manager;
  _TrayManagerSelectionListener? _listener;
  bool _iconCreated = false;

  @override
  Future<void> initialize({
    required String iconAssetPath,
    required String toolTip,
    required WindowsTraySelectionCallback onSelected,
    required WindowsTrayIconGestureCallback onIconGesture,
  }) async {
    if (_listener != null) {
      throw StateError('Tray manager plugin is already initialized.');
    }
    final _TrayManagerSelectionListener listener =
        _TrayManagerSelectionListener(onSelected, onIconGesture);
    _listener = listener;
    _manager.addListener(listener);
    try {
      _iconCreated = true;
      await _manager.setIcon(iconAssetPath);
      await _manager.setToolTip(toolTip);
    } on Object {
      _manager.removeListener(listener);
      _listener = null;
      if (_iconCreated) {
        await _manager.destroy();
        _iconCreated = false;
      }
      rethrow;
    }
  }

  @override
  Future<void> replaceMenu(List<WindowsTrayMenuEntry> entries) {
    if (_listener == null) {
      throw StateError('Tray manager plugin is not initialized.');
    }
    final Menu menu = Menu(
      items: entries
          .map((WindowsTrayMenuEntry entry) {
            return MenuItem(
              key: entry.command.name,
              label: entry.label,
              disabled: !entry.enabled,
            );
          })
          .toList(growable: false),
    );
    return _manager.setContextMenu(menu);
  }

  @override
  Future<void> popUpContextMenu() {
    if (_listener == null) {
      throw StateError('Tray manager plugin is not initialized.');
    }
    return _manager.popUpContextMenu();
  }

  @override
  Future<void> dispose() async {
    final _TrayManagerSelectionListener? listener = _listener;
    if (listener == null) {
      if (_iconCreated) {
        await _manager.destroy();
        _iconCreated = false;
      }
      return;
    }
    _listener = null;
    _manager.removeListener(listener);
    if (_iconCreated) {
      await _manager.destroy();
      _iconCreated = false;
    }
  }
}

final class _TrayManagerSelectionListener with TrayListener {
  _TrayManagerSelectionListener(this._onSelected, this._onIconGesture);

  final WindowsTraySelectionCallback _onSelected;
  final WindowsTrayIconGestureCallback _onIconGesture;

  @override
  void onTrayIconMouseDown() {
    _onIconGesture(WindowsTrayIconGesture.primary);
  }

  @override
  void onTrayIconRightMouseDown() {
    _onIconGesture(WindowsTrayIconGesture.secondary);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final String? key = menuItem.key;
    for (final WindowsTrayCommand command in WindowsTrayCommand.values) {
      if (command.name == key) {
        _onSelected(command);
        return;
      }
    }
  }
}
