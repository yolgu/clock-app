import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_session.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/windows/windows_tray_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const WindowsTrayLabels labels = WindowsTrayLabels(
    open: 'Open Clock Rhythm',
    pause: 'Pause',
    resume: 'Resume',
    stopForToday: 'Stop for Today',
    quit: 'Quit Clock Rhythm',
  );

  test(
    'publishes exactly five localized commands with running enablement',
    () async {
      final FakeWindowsTrayPlugin plugin = FakeWindowsTrayPlugin();
      final List<WindowsTrayCommand> commands = <WindowsTrayCommand>[];
      final WindowsTrayAdapter adapter = WindowsTrayAdapter(
        plugin: plugin,
        onCommand: commands.add,
      );

      await adapter.initialize(
        labels: labels,
        status: RhythmSessionStatus.running,
      );

      expect(plugin.iconAssetPath, 'windows/runner/resources/app_icon.ico');
      expect(plugin.toolTip, 'Clock Rhythm');
      expect(plugin.menuEntries, const <WindowsTrayMenuEntry>[
        WindowsTrayMenuEntry(
          command: WindowsTrayCommand.open,
          label: 'Open Clock Rhythm',
          enabled: true,
        ),
        WindowsTrayMenuEntry(
          command: WindowsTrayCommand.pause,
          label: 'Pause',
          enabled: true,
        ),
        WindowsTrayMenuEntry(
          command: WindowsTrayCommand.resume,
          label: 'Resume',
          enabled: false,
        ),
        WindowsTrayMenuEntry(
          command: WindowsTrayCommand.stopForToday,
          label: 'Stop for Today',
          enabled: true,
        ),
        WindowsTrayMenuEntry(
          command: WindowsTrayCommand.quit,
          label: 'Quit Clock Rhythm',
          enabled: true,
        ),
      ]);

      plugin.click(WindowsTrayCommand.open);
      plugin.click(WindowsTrayCommand.pause);
      plugin.click(WindowsTrayCommand.resume);
      plugin.click(WindowsTrayCommand.stopForToday);
      plugin.click(WindowsTrayCommand.quit);

      expect(commands, <WindowsTrayCommand>[
        WindowsTrayCommand.open,
        WindowsTrayCommand.pause,
        WindowsTrayCommand.stopForToday,
        WindowsTrayCommand.quit,
      ]);
    },
  );

  test(
    'replaces labels and enablement when the session state changes',
    () async {
      final FakeWindowsTrayPlugin plugin = FakeWindowsTrayPlugin();
      final List<WindowsTrayCommand> commands = <WindowsTrayCommand>[];
      final WindowsTrayAdapter adapter = WindowsTrayAdapter(
        plugin: plugin,
        onCommand: commands.add,
      );
      await adapter.initialize(
        labels: labels,
        status: RhythmSessionStatus.paused,
      );

      await adapter.update(
        labels: const WindowsTrayLabels(
          open: '열기',
          pause: '일시정지',
          resume: '재개',
          stopForToday: '오늘 종료',
          quit: 'Clock Rhythm 완전 종료',
        ),
        status: RhythmSessionStatus.stoppedForToday,
      );

      expect(plugin.menuEntries[0].label, '열기');
      expect(plugin.menuEntries[1].enabled, isFalse);
      expect(plugin.menuEntries[2].enabled, isFalse);
      expect(plugin.menuEntries[3].enabled, isFalse);

      plugin.click(WindowsTrayCommand.open);
      plugin.click(WindowsTrayCommand.stopForToday);
      expect(commands, <WindowsTrayCommand>[WindowsTrayCommand.open]);
    },
  );

  test('each enabled plugin click invokes one typed callback', () async {
    final FakeWindowsTrayPlugin plugin = FakeWindowsTrayPlugin();
    final List<WindowsTrayCommand> commands = <WindowsTrayCommand>[];
    final WindowsTrayAdapter adapter = WindowsTrayAdapter(
      plugin: plugin,
      onCommand: commands.add,
    );
    await adapter.initialize(
      labels: labels,
      status: RhythmSessionStatus.paused,
    );

    plugin.click(WindowsTrayCommand.resume);
    plugin.click(WindowsTrayCommand.resume);

    expect(commands, <WindowsTrayCommand>[
      WindowsTrayCommand.resume,
      WindowsTrayCommand.resume,
    ]);
  });

  test(
    'left and right icon gestures open the menu before one command selection',
    () async {
      final FakeWindowsTrayPlugin plugin = FakeWindowsTrayPlugin();
      final List<WindowsTrayCommand> commands = <WindowsTrayCommand>[];
      final WindowsTrayAdapter adapter = WindowsTrayAdapter(
        plugin: plugin,
        onCommand: commands.add,
      );
      await adapter.initialize(
        labels: labels,
        status: RhythmSessionStatus.running,
      );

      plugin.gesture(WindowsTrayIconGesture.primary);
      plugin.gesture(WindowsTrayIconGesture.secondary);
      await adapter.flushPendingPluginWork();

      expect(plugin.popUpRequests, 2);
      expect(commands, isEmpty);

      plugin.click(WindowsTrayCommand.pause);
      expect(commands, <WindowsTrayCommand>[WindowsTrayCommand.pause]);
    },
  );

  test('the packaged Windows tray icon is an ICO resource', () async {
    final ByteData icon = await rootBundle.load(
      'windows/runner/resources/app_icon.ico',
    );
    final Uint8List bytes = icon.buffer.asUint8List(
      icon.offsetInBytes,
      icon.lengthInBytes,
    );

    expect(bytes.length, greaterThan(4));
    expect(bytes.take(4), <int>[0, 0, 1, 0]);
  });

  test('disposal removes callbacks and destroys the tray once', () async {
    final FakeWindowsTrayPlugin plugin = FakeWindowsTrayPlugin();
    final List<WindowsTrayCommand> commands = <WindowsTrayCommand>[];
    final WindowsTrayAdapter adapter = WindowsTrayAdapter(
      plugin: plugin,
      onCommand: commands.add,
    );
    await adapter.initialize(labels: labels, status: RhythmSessionStatus.idle);

    await adapter.dispose();
    await adapter.dispose();
    plugin.click(WindowsTrayCommand.open);

    expect(plugin.disposeRequests, 1);
    expect(commands, isEmpty);
  });
}

final class FakeWindowsTrayPlugin implements WindowsTrayPlugin {
  String? iconAssetPath;
  String? toolTip;
  List<WindowsTrayMenuEntry> menuEntries = <WindowsTrayMenuEntry>[];
  WindowsTraySelectionCallback? selectionCallback;
  WindowsTrayIconGestureCallback? iconGestureCallback;
  int disposeRequests = 0;
  int popUpRequests = 0;

  void click(WindowsTrayCommand command) {
    selectionCallback?.call(command);
  }

  void gesture(WindowsTrayIconGesture gesture) {
    iconGestureCallback?.call(gesture);
  }

  @override
  Future<void> initialize({
    required String iconAssetPath,
    required String toolTip,
    required WindowsTraySelectionCallback onSelected,
    required WindowsTrayIconGestureCallback onIconGesture,
  }) async {
    this.iconAssetPath = iconAssetPath;
    this.toolTip = toolTip;
    selectionCallback = onSelected;
    iconGestureCallback = onIconGesture;
  }

  @override
  Future<void> popUpContextMenu() async {
    popUpRequests += 1;
  }

  @override
  Future<void> replaceMenu(List<WindowsTrayMenuEntry> entries) async {
    menuEntries = List<WindowsTrayMenuEntry>.unmodifiable(entries);
  }

  @override
  Future<void> dispose() async {
    disposeRequests += 1;
    selectionCallback = null;
    iconGestureCallback = null;
  }
}
