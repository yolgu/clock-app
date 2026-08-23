import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

final class StagedPrivateSound {
  const StagedPrivateSound({
    required this.candidatePath,
    required this.privatePath,
  });

  final String candidatePath;
  final String privatePath;
}

abstract interface class PrivateSoundDirectoryProvider {
  Future<String> applicationSupportPath();
}

final class PathProviderPrivateSoundDirectoryProvider
    implements PrivateSoundDirectoryProvider {
  const PathProviderPrivateSoundDirectoryProvider();

  @override
  Future<String> applicationSupportPath() async {
    return (await getApplicationSupportDirectory()).path;
  }
}

abstract interface class PrivateSoundVersionGenerator {
  String next();
}

final class SecurePrivateSoundVersionGenerator
    implements PrivateSoundVersionGenerator {
  SecurePrivateSoundVersionGenerator({Random? random})
    : _random = random ?? Random.secure();

  final Random _random;

  @override
  String next() {
    final String randomPart = List<String>.generate(
      4,
      (int _) => _random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
      growable: false,
    ).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }
}

abstract interface class PrivateSoundFileSystem {
  Future<void> createDirectory(String path);

  Future<void> copyFile(String sourcePath, String targetPath);

  Future<void> moveFile(String sourcePath, String targetPath);

  Future<Uint8List> readFile(String path);

  Future<int> fileLength(String path);

  Future<List<String>> listFilePaths(String directoryPath);

  Future<bool> fileExists(String path);

  Future<void> deleteFile(String path);
}

final class DartIoPrivateSoundFileSystem implements PrivateSoundFileSystem {
  const DartIoPrivateSoundFileSystem();

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {
    await File(sourcePath).copy(targetPath);
  }

  @override
  Future<void> moveFile(String sourcePath, String targetPath) async {
    await File(sourcePath).rename(targetPath);
  }

  @override
  Future<Uint8List> readFile(String path) => File(path).readAsBytes();

  @override
  Future<int> fileLength(String path) => File(path).length();

  @override
  Future<List<String>> listFilePaths(String directoryPath) async {
    final Directory directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return const <String>[];
    }
    return directory
        .list(followLinks: false)
        .where((FileSystemEntity entity) => entity is File)
        .map((FileSystemEntity entity) => entity.path)
        .toList();
  }

  @override
  Future<bool> fileExists(String path) => File(path).exists();

  @override
  Future<void> deleteFile(String path) => File(path).delete();
}

final class PrivateSoundStore {
  factory PrivateSoundStore({
    PrivateSoundDirectoryProvider directoryProvider =
        const PathProviderPrivateSoundDirectoryProvider(),
    PrivateSoundFileSystem fileSystem = const DartIoPrivateSoundFileSystem(),
    PrivateSoundVersionGenerator? versionGenerator,
  }) {
    return PrivateSoundStore._(
      directoryProvider,
      fileSystem,
      versionGenerator ?? SecurePrivateSoundVersionGenerator(),
    );
  }

  const PrivateSoundStore._(
    this._directoryProvider,
    this._fileSystem,
    this._versionGenerator,
  );

  static const String directoryName = 'notification-sounds';
  static final RegExp _privateFileName = RegExp(
    r'^notification-[A-Za-z0-9_-]+\.mp3$',
  );
  static final RegExp _candidateFileName = RegExp(
    r'^\.notification-[A-Za-z0-9_-]+\.candidate\.mp3$',
  );

  final PrivateSoundDirectoryProvider _directoryProvider;
  final PrivateSoundFileSystem _fileSystem;
  final PrivateSoundVersionGenerator _versionGenerator;

  Future<StagedPrivateSound> stage(String sourcePath) async {
    final String directoryPath = await _soundDirectoryPath();
    await _fileSystem.createDirectory(directoryPath);
    final String version = _validatedVersion(_versionGenerator.next());
    final StagedPrivateSound staged = StagedPrivateSound(
      candidatePath: _join(
        directoryPath,
        '.notification-$version.candidate.mp3',
      ),
      privatePath: _join(directoryPath, 'notification-$version.mp3'),
    );
    if (await _fileSystem.fileExists(staged.candidatePath) ||
        await _fileSystem.fileExists(staged.privatePath)) {
      throw StateError('Private sound version already exists.');
    }
    try {
      await _fileSystem.copyFile(sourcePath, staged.candidatePath);
      return staged;
    } on Object {
      await _deleteIfExists(staged.candidatePath);
      rethrow;
    }
  }

  Future<Uint8List> readStaged(StagedPrivateSound staged) async {
    await _requireOwnedCandidate(staged.candidatePath);
    return _fileSystem.readFile(staged.candidatePath);
  }

  Future<int> stagedLength(StagedPrivateSound staged) async {
    await _requireOwnedCandidate(staged.candidatePath);
    return _fileSystem.fileLength(staged.candidatePath);
  }

  Future<String> promote(StagedPrivateSound staged) async {
    await _requireOwnedCandidate(staged.candidatePath);
    await _requireOwnedPrivateSound(staged.privatePath);
    await _fileSystem.moveFile(staged.candidatePath, staged.privatePath);
    return staged.privatePath;
  }

  Future<void> discardStaged(StagedPrivateSound staged) async {
    await _requireOwnedCandidate(staged.candidatePath);
    await _deleteIfExists(staged.candidatePath);
  }

  Future<void> discardPrivate(String privatePath) async {
    await _requireOwnedPrivateSound(privatePath);
    await _deleteIfExists(privatePath);
  }

  Future<bool> retainOnly(String retainedPrivatePath) async {
    await _requireOwnedPrivateSound(retainedPrivatePath);
    final String directoryPath = await _soundDirectoryPath();
    bool cleanupRequired = false;
    final List<String> paths;
    try {
      paths = await _fileSystem.listFilePaths(directoryPath);
    } on Object {
      return true;
    }
    for (final String path in paths) {
      final String name = _baseName(path);
      final bool owned =
          _privateFileName.hasMatch(name) || _candidateFileName.hasMatch(name);
      if (!owned || _samePath(path, retainedPrivatePath)) {
        continue;
      }
      try {
        await _fileSystem.deleteFile(path);
      } on Object {
        cleanupRequired = true;
      }
    }
    return cleanupRequired;
  }

  Future<String> _soundDirectoryPath() async {
    return _join(
      await _directoryProvider.applicationSupportPath(),
      directoryName,
    );
  }

  Future<void> _deleteIfExists(String path) async {
    if (await _fileSystem.fileExists(path)) {
      await _fileSystem.deleteFile(path);
    }
  }

  Future<void> _requireOwnedCandidate(String path) async {
    if (!_candidateFileName.hasMatch(_baseName(path)) ||
        !await _isDirectChildOfSoundDirectory(path)) {
      throw ArgumentError.value(path, 'path', 'is not a sound candidate');
    }
  }

  Future<void> _requireOwnedPrivateSound(String path) async {
    if (!_privateFileName.hasMatch(_baseName(path)) ||
        !await _isDirectChildOfSoundDirectory(path)) {
      throw ArgumentError.value(path, 'path', 'is not private sound media');
    }
  }

  Future<bool> _isDirectChildOfSoundDirectory(String path) async {
    final String expectedDirectory = Directory(
      await _soundDirectoryPath(),
    ).absolute.path;
    final String actualDirectory = File(path).absolute.parent.path;
    return _samePath(actualDirectory, expectedDirectory);
  }

  String _validatedVersion(String value) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      throw ArgumentError.value(value, 'version', 'contains unsafe characters');
    }
    return value;
  }
}

String _join(String directory, String name) {
  final String separator = Platform.pathSeparator;
  return directory.endsWith(separator)
      ? '$directory$name'
      : '$directory$separator$name';
}

String _baseName(String path) {
  return path.replaceAll('\\', '/').split('/').last;
}

bool _samePath(String left, String right) {
  if (Platform.isWindows) {
    return left.toLowerCase() == right.toLowerCase();
  }
  return left == right;
}
