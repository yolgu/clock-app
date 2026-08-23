import 'dart:typed_data';

enum Mp3StructureFailureCode { truncatedId3Tag, missingConsecutiveFrames }

final class Mp3StructureFailure implements Exception {
  const Mp3StructureFailure(this.code);

  final Mp3StructureFailureCode code;

  @override
  String toString() => 'Mp3StructureFailure(${code.name})';
}

final class Mp3StructureValidator {
  const Mp3StructureValidator();

  void validate(Uint8List bytes) {
    final int audioOffset = _audioOffset(bytes);
    final int scanLimit = _minimum(bytes.length - 4, audioOffset + 4096);
    for (int offset = audioOffset; offset <= scanLimit; offset += 1) {
      final int? firstFrameLength = _frameLengthAt(bytes, offset);
      if (firstFrameLength == null) {
        continue;
      }
      final int secondOffset = offset + firstFrameLength;
      if (_frameLengthAt(bytes, secondOffset) != null) {
        return;
      }
    }
    throw const Mp3StructureFailure(
      Mp3StructureFailureCode.missingConsecutiveFrames,
    );
  }

  int _audioOffset(Uint8List bytes) {
    if (bytes.length < 3 ||
        bytes[0] != 0x49 ||
        bytes[1] != 0x44 ||
        bytes[2] != 0x33) {
      return 0;
    }
    if (bytes.length < 10) {
      throw const Mp3StructureFailure(Mp3StructureFailureCode.truncatedId3Tag);
    }
    final List<int> sizeBytes = bytes.sublist(6, 10);
    if (sizeBytes.any((int value) => value & 0x80 != 0)) {
      throw const Mp3StructureFailure(Mp3StructureFailureCode.truncatedId3Tag);
    }
    final int tagSize =
        (sizeBytes[0] << 21) |
        (sizeBytes[1] << 14) |
        (sizeBytes[2] << 7) |
        sizeBytes[3];
    final int offset = 10 + tagSize;
    if (offset > bytes.length) {
      throw const Mp3StructureFailure(Mp3StructureFailureCode.truncatedId3Tag);
    }
    return offset;
  }

  int? _frameLengthAt(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) {
      return null;
    }
    final int header =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    if (header & 0xFFE00000 != 0xFFE00000) {
      return null;
    }
    final int versionBits = (header >> 19) & 0x3;
    final int layerBits = (header >> 17) & 0x3;
    final int bitrateIndex = (header >> 12) & 0xF;
    final int sampleRateIndex = (header >> 10) & 0x3;
    if (versionBits == 1 ||
        layerBits != 1 ||
        bitrateIndex == 0 ||
        bitrateIndex == 15 ||
        sampleRateIndex == 3) {
      return null;
    }

    final bool isMpeg1 = versionBits == 3;
    final int bitrateKbps = (isMpeg1
        ? _mpeg1Layer3Bitrates
        : _mpeg2Layer3Bitrates)[bitrateIndex];
    final int sampleRateDivisor = switch (versionBits) {
      3 => 1,
      2 => 2,
      0 => 4,
      _ => throw StateError('Validated MPEG version became invalid.'),
    };
    final int sampleRate = _sampleRates[sampleRateIndex] ~/ sampleRateDivisor;
    final int padding = (header >> 9) & 0x1;
    final int coefficient = isMpeg1 ? 144000 : 72000;
    final int frameLength = (coefficient * bitrateKbps ~/ sampleRate) + padding;
    if (frameLength <= 4 || offset + frameLength > bytes.length) {
      return null;
    }
    return frameLength;
  }
}

const List<int> _sampleRates = <int>[44100, 48000, 32000];
const List<int> _mpeg1Layer3Bitrates = <int>[
  0,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  160,
  192,
  224,
  256,
  320,
  0,
];
const List<int> _mpeg2Layer3Bitrates = <int>[
  0,
  8,
  16,
  24,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  144,
  160,
  0,
];

int _minimum(int left, int right) => left < right ? left : right;
