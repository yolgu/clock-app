import 'package:flutter/widgets.dart';

import 'android_delivery_dto.dart';
import 'android_rhythm_channel.dart';

@pragma('vm:entry-point')
Future<void> androidRhythmBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runAndroidRhythmBackgroundRefill(
    channel: MethodChannelAndroidRhythmChannel(),
  );
}

Future<void> runAndroidRhythmBackgroundRefill({
  required AndroidRhythmChannel channel,
  AndroidRhythmDeliveryPlanFactory planFactory =
      const AndroidRhythmDeliveryPlanFactory(),
}) async {
  int? expectedRevision;
  try {
    final Object? response = await channel.invoke(
      AndroidRhythmChannelMethod.backgroundReady,
    );
    final AndroidRhythmBackgroundRequest request =
        AndroidRhythmBackgroundRequest.fromChannelMap(
          requireAndroidRhythmChannelMap(
            response,
            AndroidRhythmChannelMethod.backgroundReady,
          ),
        );
    expectedRevision = request.expectedRevision;
    final AndroidRhythmDeliveryPlan replacement = planFactory
        .forBackgroundRefill(request);
    await channel.invoke(
      AndroidRhythmChannelMethod.completeBackgroundRefill,
      <String, Object?>{
        'expectedRevision': request.expectedRevision,
        'plan': replacement.toChannelMap(),
      },
    );
  } on Object catch (error) {
    await _reportBackgroundFailure(
      channel: channel,
      expectedRevision: expectedRevision,
      error: error,
    );
  }
}

Future<void> _reportBackgroundFailure({
  required AndroidRhythmChannel channel,
  required int? expectedRevision,
  required Object error,
}) async {
  final String code = switch (error) {
    final AndroidRhythmDeliveryFailure failure => failure.code.wireName,
    FormatException() =>
      AndroidRhythmDeliveryFailureCode.invalidPayload.wireName,
    _ => AndroidRhythmDeliveryFailureCode.backgroundRefillFailed.wireName,
  };
  try {
    await channel.invoke(
      AndroidRhythmChannelMethod.backgroundRefillFailed,
      <String, Object?>{
        'expectedRevision': expectedRevision,
        'failureCode': code,
      },
    );
  } on Object {
    // Native process recovery owns the durable marker when the channel closes.
  }
}
