import '../../domain/rhythm_event.dart';

final class RhythmNotification {
  factory RhythmNotification({
    required RhythmEvent event,
    required String title,
    required String body,
  }) {
    final String normalizedTitle = title.trim();
    final String normalizedBody = body.trim();
    if (normalizedTitle.isEmpty || normalizedBody.isEmpty) {
      throw ArgumentError('Rhythm notification copy must not be blank.');
    }
    return RhythmNotification._(
      event: event,
      title: normalizedTitle,
      body: normalizedBody,
    );
  }

  const RhythmNotification._({
    required this.event,
    required this.title,
    required this.body,
  });

  final RhythmEvent event;
  final String title;
  final String body;
}

abstract interface class NotificationPort {
  Future<void> show(RhythmNotification notification);
}
