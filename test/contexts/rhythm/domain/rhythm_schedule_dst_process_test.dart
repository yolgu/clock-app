import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves local civil cadence across a DST gap and fold', () async {
    final Directory outputDirectory = await Directory.systemTemp.createTemp(
      'clock-rhythm-dst-probe-',
    );
    addTearDown(() => outputDirectory.delete(recursive: true));
    final String compiledProbe =
        '${outputDirectory.path}/rhythm_schedule_probe.js';

    final ProcessResult compilation = await Process.run('fvm', <String>[
      'dart',
      'compile',
      'js',
      'test/fixtures/dst/rhythm_schedule_probe.dart',
      '-o',
      compiledProbe,
    ], workingDirectory: Directory.current.path);

    expect(
      compilation.exitCode,
      0,
      reason: '${compilation.stdout}${compilation.stderr}',
    );

    final Map<String, String> environment = Map<String, String>.of(
      Platform.environment,
    )..['TZ'] = 'America/New_York';
    final ProcessResult execution = await Process.run('node', <String>[
      compiledProbe,
    ], environment: environment);

    expect(
      execution.exitCode,
      0,
      reason: '${execution.stdout}${execution.stderr}',
    );
  });
}
