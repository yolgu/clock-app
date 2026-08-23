final class SelectedNotificationSound {
  const SelectedNotificationSound({
    required this.fileName,
    required this.privateSource,
  });

  final String fileName;
  final String privateSource;
}

enum NotificationSoundFileFailureCode {
  unavailableSelection,
  wrongExtension,
  fileTooLarge,
  unreadableFile,
  invalidMp3Structure,
  decoderRejected,
  privateStorage,
}

final class NotificationSoundFileFailure implements Exception {
  const NotificationSoundFileFailure({required this.code, this.cause});

  final NotificationSoundFileFailureCode code;
  final Object? cause;

  @override
  String toString() => 'NotificationSoundFileFailure(${code.name})';
}

final class NotificationSoundAdoptionResult {
  const NotificationSoundAdoptionResult({required this.cleanupRequired});

  final bool cleanupRequired;
}

abstract interface class NotificationSoundFilePort {
  static const int maximumCustomMp3MiB = 20;
  static const int maximumCustomMp3Bytes = maximumCustomMp3MiB * 1024 * 1024;

  Future<SelectedNotificationSound?> chooseCustomMp3();
}

abstract interface class TransactionalNotificationSoundFilePort
    implements NotificationSoundFilePort {
  Future<NotificationSoundAdoptionResult> confirmAdoption(
    SelectedNotificationSound sound,
  );

  Future<void> discardAdoption(SelectedNotificationSound sound);
}
