import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

import '../../application/ports/notification_sound_file_port.dart';
import 'mp3_structure_validator.dart';
import 'private_sound_store.dart';

final class WindowsPickedSoundFile {
  const WindowsPickedSoundFile({required this.name, required this.path});

  final String name;
  final String? path;
}

abstract interface class WindowsSoundFilePicker {
  Future<WindowsPickedSoundFile?> chooseSingleMp3();
}

final class FilePickerWindowsSoundFilePicker implements WindowsSoundFilePicker {
  const FilePickerWindowsSoundFilePicker();

  @override
  Future<WindowsPickedSoundFile?> chooseSingleMp3() async {
    final PlatformFile? selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['mp3'],
    );
    if (selected == null) {
      return null;
    }
    return WindowsPickedSoundFile(name: selected.name, path: selected.path);
  }
}

abstract interface class Mp3DecoderProbe {
  Future<void> prepare(String filePath);
}

final class AudioplayersMp3DecoderProbe implements Mp3DecoderProbe {
  const AudioplayersMp3DecoderProbe();

  @override
  Future<void> prepare(String filePath) async {
    final AudioPlayer player = AudioPlayer();
    Object? failure;
    StackTrace? failureStackTrace;
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(DeviceFileSource(filePath));
    } on Object catch (error, stackTrace) {
      failure = error;
      failureStackTrace = stackTrace;
    }
    try {
      await player.dispose();
    } on Object catch (error, stackTrace) {
      failure ??= error;
      failureStackTrace ??= stackTrace;
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure, failureStackTrace!);
    }
  }
}

final class WindowsNotificationSoundFileAdapter
    implements TransactionalNotificationSoundFilePort {
  factory WindowsNotificationSoundFileAdapter({
    WindowsSoundFilePicker picker = const FilePickerWindowsSoundFilePicker(),
    PrivateSoundStore? privateStore,
    Mp3StructureValidator validator = const Mp3StructureValidator(),
    Mp3DecoderProbe decoderProbe = const AudioplayersMp3DecoderProbe(),
  }) {
    return WindowsNotificationSoundFileAdapter._(
      picker,
      privateStore ?? PrivateSoundStore(),
      validator,
      decoderProbe,
    );
  }

  const WindowsNotificationSoundFileAdapter._(
    this._picker,
    this._privateStore,
    this._validator,
    this._decoderProbe,
  );

  final WindowsSoundFilePicker _picker;
  final PrivateSoundStore _privateStore;
  final Mp3StructureValidator _validator;
  final Mp3DecoderProbe _decoderProbe;

  @override
  Future<SelectedNotificationSound?> chooseCustomMp3() async {
    final WindowsPickedSoundFile? selected;
    try {
      selected = await _picker.chooseSingleMp3();
    } on Object catch (error) {
      throw NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.unavailableSelection,
        cause: error,
      );
    }
    if (selected == null) {
      return null;
    }
    final String fileName = selected.name.trim();
    if (fileName.isEmpty || !fileName.toLowerCase().endsWith('.mp3')) {
      throw const NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.wrongExtension,
      );
    }
    final String? sourcePath = selected.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      throw const NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.unavailableSelection,
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.mp3')) {
      throw const NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.wrongExtension,
      );
    }

    final FileStat sourceStat;
    try {
      sourceStat = await File(sourcePath).stat();
    } on Object catch (error) {
      throw NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.unreadableFile,
        cause: error,
      );
    }
    if (sourceStat.type != FileSystemEntityType.file) {
      throw const NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.unreadableFile,
      );
    }
    if (sourceStat.size > NotificationSoundFilePort.maximumCustomMp3Bytes) {
      throw const NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.fileTooLarge,
      );
    }

    final StagedPrivateSound staged;
    try {
      staged = await _privateStore.stage(sourcePath);
    } on Object catch (error) {
      throw NotificationSoundFileFailure(
        code: NotificationSoundFileFailureCode.privateStorage,
        cause: error,
      );
    }
    try {
      final int candidateLength;
      try {
        candidateLength = await _privateStore.stagedLength(staged);
      } on Object catch (error) {
        throw NotificationSoundFileFailure(
          code: NotificationSoundFileFailureCode.privateStorage,
          cause: error,
        );
      }
      if (candidateLength > NotificationSoundFilePort.maximumCustomMp3Bytes) {
        throw const NotificationSoundFileFailure(
          code: NotificationSoundFileFailureCode.fileTooLarge,
        );
      }
      try {
        final Uint8List candidateBytes;
        try {
          candidateBytes = await _privateStore.readStaged(staged);
        } on Object catch (error) {
          throw NotificationSoundFileFailure(
            code: NotificationSoundFileFailureCode.privateStorage,
            cause: error,
          );
        }
        if (candidateBytes.length >
            NotificationSoundFilePort.maximumCustomMp3Bytes) {
          throw const NotificationSoundFileFailure(
            code: NotificationSoundFileFailureCode.fileTooLarge,
          );
        }
        _validator.validate(candidateBytes);
      } on Mp3StructureFailure catch (error) {
        throw NotificationSoundFileFailure(
          code: NotificationSoundFileFailureCode.invalidMp3Structure,
          cause: error,
        );
      }
      try {
        await _decoderProbe.prepare(staged.candidatePath);
      } on Object catch (error) {
        throw NotificationSoundFileFailure(
          code: NotificationSoundFileFailureCode.decoderRejected,
          cause: error,
        );
      }
      final String privatePath;
      try {
        privatePath = await _privateStore.promote(staged);
      } on Object catch (error) {
        throw NotificationSoundFileFailure(
          code: NotificationSoundFileFailureCode.privateStorage,
          cause: error,
        );
      }
      return SelectedNotificationSound(
        fileName: fileName,
        privateSource: privatePath,
      );
    } on Object {
      try {
        await _privateStore.discardStaged(staged);
      } on Object {
        // The rejected candidate is never returned or made durable.
      }
      rethrow;
    }
  }

  @override
  Future<NotificationSoundAdoptionResult> confirmAdoption(
    SelectedNotificationSound sound,
  ) async {
    final bool cleanupRequired = await _privateStore.retainOnly(
      sound.privateSource,
    );
    return NotificationSoundAdoptionResult(cleanupRequired: cleanupRequired);
  }

  @override
  Future<void> discardAdoption(SelectedNotificationSound sound) {
    return _privateStore.discardPrivate(sound.privateSource);
  }
}
