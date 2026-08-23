import 'dart:io';
import 'dart:typed_data';

import 'package:clock_rhythm/contexts/preferences/application/change_notification_sound.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/notification_sound_file_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/preferences_changed_port.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/settings_repository.dart';
import 'package:clock_rhythm/contexts/preferences/application/ports/sound_preview_port.dart';
import 'package:clock_rhythm/contexts/preferences/domain/notification_sound_preference.dart';
import 'package:clock_rhythm/contexts/preferences/domain/user_preferences.dart';
import 'package:clock_rhythm/contexts/preferences/infrastructure/windows/private_sound_store.dart';
import 'package:clock_rhythm/contexts/preferences/infrastructure/windows/windows_notification_sound_file_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory workspace;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp(
      'clock-rhythm-windows-sound-',
    );
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  test('selection cancellation leaves private storage untouched', () async {
    final WindowsNotificationSoundFileAdapter adapter = _adapter(
      workspace: workspace,
      picker: const FakeWindowsSoundFilePicker(null),
    );

    expect(await adapter.chooseCustomMp3(), isNull);
    expect(
      Directory(
        _join(workspace.path, PrivateSoundStore.directoryName),
      ).existsSync(),
      isFalse,
    );
  });

  test('rejects a wrong extension before creating private media', () async {
    final File source = await _writeValidMp3(workspace, 'bell.wav');
    final WindowsNotificationSoundFileAdapter adapter = _adapter(
      workspace: workspace,
      picker: FakeWindowsSoundFilePicker(
        WindowsPickedSoundFile(name: 'bell.wav', path: source.path),
      ),
    );

    await expectLater(
      adapter.chooseCustomMp3(),
      throwsA(_fileFailure(NotificationSoundFileFailureCode.wrongExtension)),
    );
    expect(_ownedPrivateFiles(workspace), isEmpty);
  });

  test('rejects a picker name that disguises a non-MP3 source path', () async {
    final File source = await _writeValidMp3(workspace, 'disguised.bin');
    final WindowsNotificationSoundFileAdapter adapter = _adapter(
      workspace: workspace,
      picker: FakeWindowsSoundFilePicker(
        WindowsPickedSoundFile(name: 'bell.mp3', path: source.path),
      ),
    );

    await expectLater(
      adapter.chooseCustomMp3(),
      throwsA(_fileFailure(NotificationSoundFileFailureCode.wrongExtension)),
    );
    expect(_ownedPrivateFiles(workspace), isEmpty);
  });

  test('rejects a file above the shared 20 MiB limit', () async {
    final File source = File(_join(workspace.path, 'large.mp3'));
    final RandomAccessFile handle = await source.open(mode: FileMode.write);
    await handle.truncate(NotificationSoundFilePort.maximumCustomMp3Bytes + 1);
    await handle.close();
    final WindowsNotificationSoundFileAdapter adapter = _adapter(
      workspace: workspace,
      picker: FakeWindowsSoundFilePicker(
        WindowsPickedSoundFile(name: 'large.mp3', path: source.path),
      ),
    );

    await expectLater(
      adapter.chooseCustomMp3(),
      throwsA(_fileFailure(NotificationSoundFileFailureCode.fileTooLarge)),
    );
    expect(_ownedPrivateFiles(workspace), isEmpty);
  });

  test('rechecks the copied candidate size before decoder adoption', () async {
    final File source = await _writeValidMp3(workspace, 'growing.mp3');
    final File old = await _writePrivateSound(workspace, 'old', _validMp3());
    final PrivateSoundStore store = PrivateSoundStore(
      directoryProvider: FixedPrivateSoundDirectoryProvider(workspace.path),
      fileSystem: const ExpandingCopyPrivateSoundFileSystem(),
      versionGenerator: QueuePrivateSoundVersionGenerator(<String>['grown']),
    );
    final FakeMp3DecoderProbe decoder = FakeMp3DecoderProbe();
    final WindowsNotificationSoundFileAdapter adapter =
        WindowsNotificationSoundFileAdapter(
          picker: FakeWindowsSoundFilePicker(
            WindowsPickedSoundFile(name: 'growing.mp3', path: source.path),
          ),
          privateStore: store,
          decoderProbe: decoder,
        );

    await expectLater(
      adapter.chooseCustomMp3(),
      throwsA(_fileFailure(NotificationSoundFileFailureCode.fileTooLarge)),
    );

    expect(decoder.preparedPaths, isEmpty);
    expect(old.existsSync(), isTrue);
    expect(_ownedPrivateFiles(workspace), <String>[old.path]);
  });

  test('invalid frame structure removes only the private candidate', () async {
    final File source = File(_join(workspace.path, 'invalid.mp3'));
    await source.writeAsBytes(<int>[1, 2, 3, 4, 5, 6]);
    final WindowsNotificationSoundFileAdapter adapter = _adapter(
      workspace: workspace,
      picker: FakeWindowsSoundFilePicker(
        WindowsPickedSoundFile(name: 'invalid.mp3', path: source.path),
      ),
    );

    await expectLater(
      adapter.chooseCustomMp3(),
      throwsA(
        _fileFailure(NotificationSoundFileFailureCode.invalidMp3Structure),
      ),
    );
    expect(_ownedPrivateFiles(workspace), isEmpty);
    expect(source.existsSync(), isTrue);
  });

  test(
    'decoder rejection removes the candidate and preserves old media',
    () async {
      final File source = await _writeValidMp3(workspace, 'new.mp3');
      final File old = await _writePrivateSound(workspace, 'old', _validMp3());
      final FakeMp3DecoderProbe decoder = FakeMp3DecoderProbe()
        ..failure = StateError('decoder rejected');
      final WindowsNotificationSoundFileAdapter adapter = _adapter(
        workspace: workspace,
        picker: FakeWindowsSoundFilePicker(
          WindowsPickedSoundFile(name: 'new.mp3', path: source.path),
        ),
        decoder: decoder,
      );

      await expectLater(
        adapter.chooseCustomMp3(),
        throwsA(_fileFailure(NotificationSoundFileFailureCode.decoderRejected)),
      );
      expect(decoder.preparedPaths.single, endsWith('.candidate.mp3'));
      expect(old.existsSync(), isTrue);
      expect(_ownedPrivateFiles(workspace), <String>[old.path]);
    },
  );

  test('adopted private copy survives source deletion', () async {
    final File source = await _writeValidMp3(workspace, 'bell.mp3');
    final WindowsNotificationSoundFileAdapter adapter = _adapter(
      workspace: workspace,
      picker: FakeWindowsSoundFilePicker(
        WindowsPickedSoundFile(name: 'bell.mp3', path: source.path),
      ),
    );

    final SelectedNotificationSound selected = (await adapter
        .chooseCustomMp3())!;
    await source.delete();

    expect(File(selected.privateSource).existsSync(), isTrue);
    expect(await File(selected.privateSource).readAsBytes(), _validMp3());
  });

  test(
    'promotion failure keeps old media and removes only the candidate',
    () async {
      final File source = await _writeValidMp3(workspace, 'new.mp3');
      final File old = await _writePrivateSound(workspace, 'old', _validMp3());
      final PrivateSoundStore store = PrivateSoundStore(
        directoryProvider: FixedPrivateSoundDirectoryProvider(workspace.path),
        fileSystem: const FailingMovePrivateSoundFileSystem(),
        versionGenerator: QueuePrivateSoundVersionGenerator(<String>['new']),
      );
      final WindowsNotificationSoundFileAdapter adapter =
          WindowsNotificationSoundFileAdapter(
            picker: FakeWindowsSoundFilePicker(
              WindowsPickedSoundFile(name: 'new.mp3', path: source.path),
            ),
            privateStore: store,
            decoderProbe: FakeMp3DecoderProbe(),
          );

      await expectLater(
        adapter.chooseCustomMp3(),
        throwsA(_fileFailure(NotificationSoundFileFailureCode.privateStorage)),
      );
      expect(old.existsSync(), isTrue);
      expect(_ownedPrivateFiles(workspace), <String>[old.path]);
    },
  );

  test(
    'failed durable save discards new media and preserves old pointer',
    () async {
      final File source = await _writeValidMp3(workspace, 'new.mp3');
      final File old = await _writePrivateSound(workspace, 'old', _validMp3());
      final UserPreferences original = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'old.mp3',
              privateSource: old.path,
            ),
          );
      final FakeSettingsRepository repository = FakeSettingsRepository(original)
        ..failSave = true;
      final WindowsNotificationSoundFileAdapter soundFiles = _adapter(
        workspace: workspace,
        picker: FakeWindowsSoundFilePicker(
          WindowsPickedSoundFile(name: 'new.mp3', path: source.path),
        ),
      );
      final ChangeNotificationSound command = ChangeNotificationSound(
        settingsRepository: repository,
        soundFilePort: soundFiles,
        soundPreview: const NoOpSoundPreview(),
        preferencesChanged: const NoOpPreferencesChanged(),
      );

      await expectLater(command.chooseCustom(), throwsStateError);

      expect(repository.current, original);
      expect(old.existsSync(), isTrue);
      expect(_ownedPrivateFiles(workspace), <String>[old.path]);
    },
  );

  test('successful durable save removes superseded private media', () async {
    final File source = await _writeValidMp3(workspace, 'new.mp3');
    final File old = await _writePrivateSound(workspace, 'old', _validMp3());
    final FakeSettingsRepository repository = FakeSettingsRepository(
      UserPreferences.defaults().changeNotificationSound(
        NotificationSoundPreference.custom(
          fileName: 'old.mp3',
          privateSource: old.path,
        ),
      ),
    );
    final WindowsNotificationSoundFileAdapter soundFiles = _adapter(
      workspace: workspace,
      picker: FakeWindowsSoundFilePicker(
        WindowsPickedSoundFile(name: 'new.mp3', path: source.path),
      ),
    );
    final ChangeNotificationSound command = ChangeNotificationSound(
      settingsRepository: repository,
      soundFilePort: soundFiles,
      soundPreview: const NoOpSoundPreview(),
      preferencesChanged: const NoOpPreferencesChanged(),
    );

    await command.chooseCustom();

    expect(old.existsSync(), isFalse);
    final String selectedPath =
        repository.current.notificationSound.privateSource!;
    expect(File(selectedPath).existsSync(), isTrue);
    expect(_ownedPrivateFiles(workspace), <String>[selectedPath]);
  });

  test(
    'discard refuses a matching file name outside private storage',
    () async {
      final File external = await _writeValidMp3(
        workspace,
        'notification-external.mp3',
      );
      final WindowsNotificationSoundFileAdapter adapter = _adapter(
        workspace: workspace,
        picker: const FakeWindowsSoundFilePicker(null),
      );

      await expectLater(
        adapter.discardAdoption(
          SelectedNotificationSound(
            fileName: 'external.mp3',
            privateSource: external.path,
          ),
        ),
        throwsArgumentError,
      );
      expect(external.existsSync(), isTrue);
    },
  );
}

WindowsNotificationSoundFileAdapter _adapter({
  required Directory workspace,
  required WindowsSoundFilePicker picker,
  Mp3DecoderProbe? decoder,
}) {
  return WindowsNotificationSoundFileAdapter(
    picker: picker,
    privateStore: PrivateSoundStore(
      directoryProvider: FixedPrivateSoundDirectoryProvider(workspace.path),
      versionGenerator: QueuePrivateSoundVersionGenerator(<String>['next']),
    ),
    decoderProbe: decoder ?? FakeMp3DecoderProbe(),
  );
}

Matcher _fileFailure(NotificationSoundFileFailureCode code) {
  return isA<NotificationSoundFileFailure>().having(
    (NotificationSoundFileFailure failure) => failure.code,
    'code',
    code,
  );
}

Future<File> _writeValidMp3(Directory workspace, String name) async {
  final File file = File(_join(workspace.path, name));
  await file.writeAsBytes(_validMp3());
  return file;
}

Future<File> _writePrivateSound(
  Directory workspace,
  String version,
  Uint8List bytes,
) async {
  final Directory directory = Directory(
    _join(workspace.path, PrivateSoundStore.directoryName),
  );
  await directory.create(recursive: true);
  final File file = File(_join(directory.path, 'notification-$version.mp3'));
  await file.writeAsBytes(bytes);
  return file;
}

Uint8List _validMp3() {
  const List<int> header = <int>[0xFF, 0xFB, 0x90, 0x00];
  const int frameLength = 417;
  final Uint8List bytes = Uint8List(frameLength * 2);
  bytes.setAll(0, header);
  bytes.setAll(frameLength, header);
  return bytes;
}

List<String> _ownedPrivateFiles(Directory workspace) {
  final Directory directory = Directory(
    _join(workspace.path, PrivateSoundStore.directoryName),
  );
  if (!directory.existsSync()) {
    return const <String>[];
  }
  final List<String> paths =
      directory
          .listSync(followLinks: false)
          .whereType<File>()
          .map((File file) => file.path)
          .toList()
        ..sort();
  return paths;
}

String _join(String directory, String name) {
  return '$directory${Platform.pathSeparator}$name';
}

final class FakeWindowsSoundFilePicker implements WindowsSoundFilePicker {
  const FakeWindowsSoundFilePicker(this.selected);

  final WindowsPickedSoundFile? selected;

  @override
  Future<WindowsPickedSoundFile?> chooseSingleMp3() async => selected;
}

final class FakeMp3DecoderProbe implements Mp3DecoderProbe {
  Object? failure;
  final List<String> preparedPaths = <String>[];

  @override
  Future<void> prepare(String filePath) async {
    preparedPaths.add(filePath);
    final Object? currentFailure = failure;
    if (currentFailure != null) {
      throw currentFailure;
    }
  }
}

final class FixedPrivateSoundDirectoryProvider
    implements PrivateSoundDirectoryProvider {
  const FixedPrivateSoundDirectoryProvider(this.path);

  final String path;

  @override
  Future<String> applicationSupportPath() async => path;
}

final class QueuePrivateSoundVersionGenerator
    implements PrivateSoundVersionGenerator {
  QueuePrivateSoundVersionGenerator(this._versions);

  final List<String> _versions;

  @override
  String next() => _versions.removeAt(0);
}

final class FailingMovePrivateSoundFileSystem
    implements PrivateSoundFileSystem {
  const FailingMovePrivateSoundFileSystem();

  static const DartIoPrivateSoundFileSystem _delegate =
      DartIoPrivateSoundFileSystem();

  @override
  Future<void> copyFile(String sourcePath, String targetPath) {
    return _delegate.copyFile(sourcePath, targetPath);
  }

  @override
  Future<void> createDirectory(String path) {
    return _delegate.createDirectory(path);
  }

  @override
  Future<void> deleteFile(String path) => _delegate.deleteFile(path);

  @override
  Future<bool> fileExists(String path) => _delegate.fileExists(path);

  @override
  Future<int> fileLength(String path) => _delegate.fileLength(path);

  @override
  Future<List<String>> listFilePaths(String directoryPath) {
    return _delegate.listFilePaths(directoryPath);
  }

  @override
  Future<void> moveFile(String sourcePath, String targetPath) {
    throw StateError('fault injected before private sound promotion');
  }

  @override
  Future<Uint8List> readFile(String path) => _delegate.readFile(path);
}

final class ExpandingCopyPrivateSoundFileSystem
    implements PrivateSoundFileSystem {
  const ExpandingCopyPrivateSoundFileSystem();

  static const DartIoPrivateSoundFileSystem _delegate =
      DartIoPrivateSoundFileSystem();

  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    await _delegate.copyFile(sourcePath, targetPath);
    final RandomAccessFile handle = await File(
      targetPath,
    ).open(mode: FileMode.append);
    await handle.truncate(NotificationSoundFilePort.maximumCustomMp3Bytes + 1);
    await handle.close();
  }

  @override
  Future<void> createDirectory(String path) {
    return _delegate.createDirectory(path);
  }

  @override
  Future<void> deleteFile(String path) => _delegate.deleteFile(path);

  @override
  Future<bool> fileExists(String path) => _delegate.fileExists(path);

  @override
  Future<int> fileLength(String path) => _delegate.fileLength(path);

  @override
  Future<List<String>> listFilePaths(String directoryPath) {
    return _delegate.listFilePaths(directoryPath);
  }

  @override
  Future<void> moveFile(String sourcePath, String targetPath) {
    return _delegate.moveFile(sourcePath, targetPath);
  }

  @override
  Future<Uint8List> readFile(String path) => _delegate.readFile(path);
}

final class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository(this.current);

  UserPreferences current;
  bool failSave = false;

  @override
  Future<UserPreferences> load() async => current;

  @override
  Future<void> save(UserPreferences preferences) async {
    if (failSave) {
      throw StateError('durable save failed');
    }
    current = preferences;
  }
}

final class NoOpSoundPreview implements SoundPreviewPort {
  const NoOpSoundPreview();

  @override
  Future<SoundPreviewPlayback> play(NotificationSoundPreference sound) async {
    return SoundPreviewPlayback(completed: Future<void>.value());
  }

  @override
  Future<void> stop() async {}
}

final class NoOpPreferencesChanged implements PreferencesChangedPort {
  const NoOpPreferencesChanged();

  @override
  Future<void> publish(PreferencesChangedEvent event) async {}
}
