import 'package:clock_rhythm/contexts/preferences/public_presentation.dart'
    show BundledNotificationSound;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundles the product icon and default notification sound', () async {
    final ByteData icon = await rootBundle.load('assets/images/icon.png');
    final ByteData sound = await rootBundle.load(
      BundledNotificationSound.assetPath,
    );

    expect(icon.lengthInBytes, 2210);
    expect(sound.lengthInBytes, 688125);
  });
}
