import 'dart:io';
import 'dart:typed_data';

import 'package:clock_rhythm/contexts/preferences/infrastructure/windows/mp3_structure_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Mp3StructureValidator validator = Mp3StructureValidator();

  test('accepts two consecutive MPEG-1 Layer III frames', () {
    expect(() => validator.validate(_twoMp3Frames()), returnsNormally);
  });

  test('skips a valid ID3v2 tag before checking audio frames', () {
    final Uint8List frames = _twoMp3Frames();
    final Uint8List tagged = Uint8List(14 + frames.length)
      ..setAll(0, const <int>[0x49, 0x44, 0x33, 4, 0, 0, 0, 0, 0, 4])
      ..setAll(14, frames);

    expect(() => validator.validate(tagged), returnsNormally);
  });

  test('rejects arbitrary bytes and a truncated ID3 tag', () {
    expect(
      () => validator.validate(Uint8List.fromList(<int>[0, 1, 2, 3, 4])),
      throwsA(
        isA<Mp3StructureFailure>().having(
          (Mp3StructureFailure failure) => failure.code,
          'code',
          Mp3StructureFailureCode.missingConsecutiveFrames,
        ),
      ),
    );
    expect(
      () => validator.validate(Uint8List.fromList(<int>[0x49, 0x44, 0x33, 4])),
      throwsA(
        isA<Mp3StructureFailure>().having(
          (Mp3StructureFailure failure) => failure.code,
          'code',
          Mp3StructureFailureCode.truncatedId3Tag,
        ),
      ),
    );
  });

  test('accepts the bundled notification MP3 fixture', () async {
    final Uint8List bytes = await File(
      'assets/audio/CHIME14.mp3',
    ).readAsBytes();

    expect(() => validator.validate(bytes), returnsNormally);
  });
}

Uint8List _twoMp3Frames() {
  const List<int> header = <int>[0xFF, 0xFB, 0x90, 0x00];
  const int frameLength = 417;
  final Uint8List bytes = Uint8List(frameLength * 2);
  bytes.setAll(0, header);
  bytes.setAll(frameLength, header);
  return bytes;
}
