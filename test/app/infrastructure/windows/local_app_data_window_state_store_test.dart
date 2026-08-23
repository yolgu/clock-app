import 'dart:convert';
import 'dart:typed_data';

import 'package:clock_rhythm/app/infrastructure/windows/local_app_data_window_state_store.dart';
import 'package:clock_rhythm/app/infrastructure/windows/windows_window_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String identity = 'dev.wndls.clockrhythm';
  const WindowsWindowState expected = WindowsWindowState(
    placement: WindowsWindowPlacement(
      bounds: WindowsWindowBounds(
        left: 100,
        top: 120,
        width: 1380,
        height: 1020,
      ),
      dpi: 144,
    ),
    maximized: true,
  );

  test(
    'writes strict identity-bound state through the atomic file boundary',
    () async {
      final FakeWindowsLocalStateFile file = FakeWindowsLocalStateFile();
      final LocalAppDataWindowStateStore store = LocalAppDataWindowStateStore(
        stateFile: file,
      );

      await store.save(applicationIdentity: identity, state: expected);

      expect(file.atomicWriteCount, 1);
      final Object? decoded = jsonDecode(file.document!);
      expect(decoded, <String, Object>{
        'schemaVersion': 2,
        'kind': 'windows-window-state',
        'applicationIdentity': identity,
        'placement': <String, int>{
          'left': 100,
          'top': 120,
          'width': 1380,
          'height': 1020,
          'dpi': 144,
        },
        'maximized': true,
      });
    },
  );

  test('restores valid Local AppData state', () async {
    final FakeWindowsLocalStateFile file = FakeWindowsLocalStateFile();
    final LocalAppDataWindowStateStore store = LocalAppDataWindowStateStore(
      stateFile: file,
    );
    await store.save(applicationIdentity: identity, state: expected);

    final WindowsWindowState? restored = await store.load(
      applicationIdentity: identity,
    );

    expect(restored, expected);
    expect(file.deleteCount, 0);
  });

  test(
    'deletes corrupt state and falls back without blocking startup',
    () async {
      final FakeWindowsLocalStateFile file = FakeWindowsLocalStateFile()
        ..bytes = Uint8List.fromList(utf8.encode('{'));
      final LocalAppDataWindowStateStore store = LocalAppDataWindowStateStore(
        stateFile: file,
      );

      final WindowsWindowState? restored = await store.load(
        applicationIdentity: identity,
      );

      expect(restored, isNull);
      expect(file.deleteCount, 1);
    },
  );

  test('rejects a roaming or escaping location before reading', () async {
    final FakeWindowsLocalStateFile file = FakeWindowsLocalStateFile()
      ..location = const WindowsLocalStateLocation(
        root: r'C:\Users\Test\AppData\Local',
        directory:
            r'C:\Users\Test\AppData\Roaming\Clock Rhythm\dev.wndls.clockrhythm',
        file:
            r'C:\Users\Test\AppData\Roaming\Clock Rhythm\dev.wndls.clockrhythm\window-state.json',
      );
    final LocalAppDataWindowStateStore store = LocalAppDataWindowStateStore(
      stateFile: file,
    );

    await expectLater(
      store.load(applicationIdentity: identity),
      throwsA(isA<FormatException>()),
    );
    expect(file.readCount, 0);
  });
}

final class FakeWindowsLocalStateFile implements WindowsLocalStateFile {
  WindowsLocalStateLocation location = const WindowsLocalStateLocation(
    root: r'C:\Users\Test\AppData\Local',
    directory:
        r'C:\Users\Test\AppData\Local\Clock Rhythm\dev.wndls.clockrhythm',
    file:
        r'C:\Users\Test\AppData\Local\Clock Rhythm\dev.wndls.clockrhythm\window-state.json',
  );
  Uint8List? bytes;
  String? document;
  int atomicWriteCount = 0;
  int deleteCount = 0;
  int readCount = 0;

  @override
  Future<void> delete({required String applicationIdentity}) async {
    deleteCount += 1;
    bytes = null;
    document = null;
  }

  @override
  Future<WindowsLocalStateLocation> locate({
    required String applicationIdentity,
  }) async {
    return location;
  }

  @override
  Future<Uint8List?> read({required String applicationIdentity}) async {
    readCount += 1;
    return bytes;
  }

  @override
  Future<void> writeAtomic({
    required String applicationIdentity,
    required String document,
  }) async {
    atomicWriteCount += 1;
    this.document = document;
    bytes = Uint8List.fromList(utf8.encode(document));
  }
}
