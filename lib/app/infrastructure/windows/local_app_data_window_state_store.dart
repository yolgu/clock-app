import 'dart:convert';

import 'package:flutter/services.dart';

import 'windows_window_state.dart';

final class WindowsLocalStateLocation {
  const WindowsLocalStateLocation({
    required this.root,
    required this.directory,
    required this.file,
  });

  final String root;
  final String directory;
  final String file;

  bool isValidFor(String applicationIdentity) {
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(applicationIdentity)) {
      return false;
    }
    final String normalizedRoot = _normalize(root);
    final String normalizedDirectory = _normalize(directory);
    final String normalizedFile = _normalize(file);
    if (!_isAbsoluteWindowsPath(normalizedRoot) ||
        normalizedDirectory.contains(r'\..\') ||
        normalizedFile.contains(r'\..\')) {
      return false;
    }
    final String expectedDirectorySuffix =
        '\\clock rhythm\\${applicationIdentity.toLowerCase()}';
    return normalizedDirectory.startsWith('$normalizedRoot\\') &&
        normalizedDirectory.endsWith(expectedDirectorySuffix) &&
        normalizedFile == '$normalizedDirectory\\window-state.json';
  }

  String _normalize(String value) {
    return value
        .replaceAll('/', r'\')
        .replaceAll(RegExp(r'\\+$'), '')
        .toLowerCase();
  }

  bool _isAbsoluteWindowsPath(String value) {
    return RegExp(r'^[a-z]:\\').hasMatch(value) || value.startsWith(r'\\');
  }
}

abstract interface class WindowsLocalStateFile {
  Future<WindowsLocalStateLocation> locate({
    required String applicationIdentity,
  });

  Future<Uint8List?> read({required String applicationIdentity});

  Future<void> writeAtomic({
    required String applicationIdentity,
    required String document,
  });

  Future<void> delete({required String applicationIdentity});
}

final class LocalAppDataWindowStateStore implements WindowsWindowStateStore {
  LocalAppDataWindowStateStore({WindowsLocalStateFile? stateFile})
    : _stateFile = stateFile ?? MethodChannelWindowsLocalStateFile();

  static const int _schemaVersion = 2;
  static const String _documentKind = 'windows-window-state';
  static const Set<String> _documentKeys = <String>{
    'schemaVersion',
    'kind',
    'applicationIdentity',
    'placement',
    'maximized',
  };
  static const Set<String> _placementKeys = <String>{
    'left',
    'top',
    'width',
    'height',
    'dpi',
  };

  final WindowsLocalStateFile _stateFile;

  @override
  Future<WindowsWindowState?> load({
    required String applicationIdentity,
  }) async {
    await _requireLocalLocation(applicationIdentity);
    final Uint8List? bytes = await _stateFile.read(
      applicationIdentity: applicationIdentity,
    );
    if (bytes == null) {
      return null;
    }
    try {
      final String document = utf8.decode(bytes, allowMalformed: false);
      return _decode(document, applicationIdentity);
    } on FormatException {
      await _removeInvalidDocument(applicationIdentity);
      return null;
    }
  }

  @override
  Future<void> save({
    required String applicationIdentity,
    required WindowsWindowState state,
  }) async {
    await _requireLocalLocation(applicationIdentity);
    if (!state.placement.isValid) {
      throw ArgumentError.value(
        state.placement,
        'state',
        'contains an invalid physical window placement',
      );
    }
    final String document = jsonEncode(<String, Object>{
      'schemaVersion': _schemaVersion,
      'kind': _documentKind,
      'applicationIdentity': applicationIdentity,
      'placement': <String, int>{
        'left': state.placement.bounds.left,
        'top': state.placement.bounds.top,
        'width': state.placement.bounds.width,
        'height': state.placement.bounds.height,
        'dpi': state.placement.dpi,
      },
      'maximized': state.maximized,
    });
    await _stateFile.writeAtomic(
      applicationIdentity: applicationIdentity,
      document: document,
    );
  }

  WindowsWindowState _decode(String document, String applicationIdentity) {
    final Object? decoded = jsonDecode(document);
    if (decoded is! Map<String, Object?> ||
        !_hasExactKeys(decoded, _documentKeys) ||
        decoded['schemaVersion'] != _schemaVersion ||
        decoded['kind'] != _documentKind ||
        decoded['applicationIdentity'] != applicationIdentity ||
        decoded['maximized'] is! bool) {
      throw const FormatException('Invalid Windows window-state document');
    }
    final Object? encodedPlacement = decoded['placement'];
    if (encodedPlacement is! Map<String, Object?> ||
        !_hasExactKeys(encodedPlacement, _placementKeys)) {
      throw const FormatException('Invalid Windows physical placement');
    }
    final WindowsWindowPlacement placement = WindowsWindowPlacement(
      bounds: WindowsWindowBounds(
        left: _integer(encodedPlacement['left']),
        top: _integer(encodedPlacement['top']),
        width: _integer(encodedPlacement['width']),
        height: _integer(encodedPlacement['height']),
      ),
      dpi: _integer(encodedPlacement['dpi']),
    );
    if (!placement.isValid) {
      throw const FormatException('Invalid Windows placement values');
    }
    return WindowsWindowState(
      placement: placement,
      maximized: decoded['maximized']! as bool,
    );
  }

  Future<void> _requireLocalLocation(String applicationIdentity) async {
    final WindowsLocalStateLocation location = await _stateFile.locate(
      applicationIdentity: applicationIdentity,
    );
    if (!location.isValidFor(applicationIdentity)) {
      throw const FormatException(
        'Windows state location is outside Local AppData',
      );
    }
  }

  int _integer(Object? value) {
    if (value is! int) {
      throw const FormatException('Window placement must use integers');
    }
    return value;
  }

  bool _hasExactKeys(Map<String, Object?> value, Set<String> expected) {
    return value.length == expected.length &&
        value.keys.every(expected.contains);
  }

  Future<void> _removeInvalidDocument(String applicationIdentity) async {
    try {
      await _stateFile.delete(applicationIdentity: applicationIdentity);
    } on Object {
      // Corrupt noncritical state cleanup is best effort.
    }
  }
}

final class MethodChannelWindowsLocalStateFile
    implements WindowsLocalStateFile {
  MethodChannelWindowsLocalStateFile({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'clock_rhythm/windows_window';

  final MethodChannel _channel;

  @override
  Future<WindowsLocalStateLocation> locate({
    required String applicationIdentity,
  }) async {
    final Object? response = await _channel.invokeMethod<Object?>(
      'getLocalStateLocation',
      <String, String>{'applicationIdentity': applicationIdentity},
    );
    if (response is! Map<Object?, Object?> ||
        response.length != 3 ||
        !response.keys.every(
          (Object? key) =>
              key is String &&
              const <String>{'root', 'directory', 'file'}.contains(key),
        )) {
      throw const FormatException('Invalid Windows local-state location');
    }
    final Object? root = response['root'];
    final Object? directory = response['directory'];
    final Object? file = response['file'];
    if (root is! String || directory is! String || file is! String) {
      throw const FormatException('Invalid Windows local-state path type');
    }
    return WindowsLocalStateLocation(
      root: root,
      directory: directory,
      file: file,
    );
  }

  @override
  Future<Uint8List?> read({required String applicationIdentity}) {
    return _channel.invokeMethod<Uint8List>(
      'readLocalWindowState',
      <String, String>{'applicationIdentity': applicationIdentity},
    );
  }

  @override
  Future<void> writeAtomic({
    required String applicationIdentity,
    required String document,
  }) {
    return _channel.invokeMethod<void>(
      'writeLocalWindowStateAtomic',
      <String, String>{
        'applicationIdentity': applicationIdentity,
        'document': document,
      },
    );
  }

  @override
  Future<void> delete({required String applicationIdentity}) {
    return _channel.invokeMethod<void>(
      'deleteLocalWindowState',
      <String, String>{'applicationIdentity': applicationIdentity},
    );
  }
}
