import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const List<String> requiredScripts = <String>[
    'tool/preflight.ps1',
    'tool/generate.ps1',
    'tool/check_generated.ps1',
    'tool/check_docs.ps1',
    'tool/verify.ps1',
    'tool/build_windows.ps1',
    'tool/build_android.ps1',
    'tool/package_windows.ps1',
    'tool/package_android.ps1',
    'tool/verify_artifact.ps1',
    'tool/test_windows_lifecycle.ps1',
    'tool/test_android_lifecycle.ps1',
    'tool/remove_stale_android_plugin_registrant.ps1',
    'tool/check_release_evidence.ps1',
    'tool/source_snapshot.ps1',
  ];

  test('declares every local quality-gate entry point', () {
    for (final String path in requiredScripts) {
      expect(File(path).existsSync(), isTrue, reason: '$path must exist');
    }
  });

  test('quality gates do not force a successful exit', () {
    for (final String path in requiredScripts.where(
      (String path) => File(path).existsSync(),
    )) {
      final String source = File(path).readAsStringSync();
      expect(
        source,
        isNot(
          matches(
            RegExp(r'^\s*exit\s+0\s*$', caseSensitive: false, multiLine: true),
          ),
        ),
        reason: '$path must preserve real failures',
      );
    }
  });

  test('PowerShell scripts avoid APIs missing from Windows PowerShell 5.1', () {
    for (final String path
        in Directory('tool')
            .listSync()
            .whereType<File>()
            .map((File file) => file.path)
            .where((String path) => path.endsWith('.ps1'))) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('[System.IO.Path]::GetRelativePath')),
        reason: '$path must run under the documented powershell command',
      );
    }
  });

  test('beta Android release does not require production signing', () {
    final String source = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();

    expect(
      source,
      contains(
        'name in setOf("assembleProductionRelease", '
        '"bundleProductionRelease")',
      ),
    );
    expect(
      source,
      isNot(contains('name != validateProductionReleaseSigning.name')),
    );
  });

  test('workflow action references are immutable commit SHAs', () {
    for (final String path in <String>[
      '.github/workflows/windows.yml',
      '.github/workflows/android.yml',
    ]) {
      final File workflow = File(path);
      expect(workflow.existsSync(), isTrue, reason: '$path must exist');
      if (!workflow.existsSync()) {
        continue;
      }
      final Iterable<String> actionReferences = workflow
          .readAsLinesSync()
          .map((String line) => line.trim())
          .where((String line) => line.startsWith('uses:'))
          .map((String line) => line.substring('uses:'.length).trim());

      expect(actionReferences, isNotEmpty);
      for (final String reference in actionReferences) {
        expect(
          reference,
          matches(RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[0-9a-f]{40}$')),
          reason: '$path has a mutable action reference: $reference',
        );
      }
    }
  });

  test('build gate preserves the first failing external exit code', () async {
    final Directory temporaryDirectory = await Directory.systemTemp.createTemp(
      'clock-rhythm-gate-exit-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final File callLog = File('${temporaryDirectory.path}/calls.txt');
    final File fakeFvm = await _createFakeFvm(
      temporaryDirectory: temporaryDirectory,
      bodyOnWindows:
          'echo %*>> "${callLog.path}"\r\n'
          'if "%1 %2 %3"=="flutter pub get" exit /b 23\r\n'
          'exit /b 0\r\n',
      bodyOnPosix:
          'echo "\$*" >> "${callLog.path}"\n'
          'if [ "\$1 \$2 \$3" = "flutter pub get" ]; then exit 23; fi\n'
          'exit 0\n',
    );
    final Map<String, String> environment = Map<String, String>.of(
      Platform.environment,
    )..['CLOCK_RHYTHM_FVM'] = fakeFvm.path;

    final ProcessResult result = await Process.run(
      _powerShellExecutable,
      <String>[
        '-NoProfile',
        '-File',
        'tool/build_windows.ps1',
        '-Flavor',
        'Beta',
        '-SkipPreflight',
      ],
      workingDirectory: Directory.current.path,
      environment: environment,
    );

    expect(result.exitCode, 23);
    expect(callLog.readAsLinesSync(), hasLength(1));
    expect(callLog.readAsStringSync(), contains('flutter pub get'));
  });

  test('generated gate detects stale output changed by locked pub get', () async {
    final Directory fixture = await Directory.systemTemp.createTemp(
      'clock-rhythm-generated-gate-',
    );
    addTearDown(() => fixture.delete(recursive: true));
    final Directory fixtureTool = Directory('${fixture.path}/tool')
      ..createSync(recursive: true);
    final Directory generated = Directory('${fixture.path}/lib/l10n/generated')
      ..createSync(recursive: true);
    File(
      'tool/check_generated.ps1',
    ).copySync('${fixtureTool.path}/check_generated.ps1');
    File('tool/generate.ps1').copySync('${fixtureTool.path}/generate.ps1');
    final File generatedFile = File('${generated.path}/app_localizations.dart')
      ..writeAsStringSync('stale');
    final File fakeFvm = await _createFakeFvm(
      temporaryDirectory: fixture,
      bodyOnWindows:
          'if "%1 %2 %3"=="flutter pub get" echo current> "${generatedFile.path}"\r\n'
          'exit /b 0\r\n',
      bodyOnPosix:
          'if [ "\$1 \$2 \$3" = "flutter pub get" ]; then printf current > "${generatedFile.path}"; fi\n'
          'exit 0\n',
    );
    final Map<String, String> environment = Map<String, String>.of(
      Platform.environment,
    )..['CLOCK_RHYTHM_FVM'] = fakeFvm.path;

    final ProcessResult result = await Process.run(
      _powerShellExecutable,
      <String>[
        '-NoProfile',
        '-File',
        '${fixtureTool.path}/check_generated.ps1',
        '-SkipPreflight',
      ],
      workingDirectory: fixture.path,
      environment: environment,
    );

    expect(result.exitCode, isNot(0));
    expect(
      '${result.stdout}${result.stderr}',
      contains('Generated output was stale'),
    );
  });

  test('production build fails closed without signing credentials', () async {
    final Directory temporaryDirectory = await Directory.systemTemp.createTemp(
      'clock-rhythm-signing-gate-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final File fakeFvm = await _createFakeFvm(
      temporaryDirectory: temporaryDirectory,
      bodyOnWindows: 'exit /b 0\r\n',
      bodyOnPosix: 'exit 0\n',
    );
    final Map<String, String> environment = Map<String, String>.of(
      Platform.environment,
    )..['CLOCK_RHYTHM_FVM'] = fakeFvm.path;
    environment
      ..remove('CLOCK_RHYTHM_WINDOWS_CERTIFICATE')
      ..remove('CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD');

    final ProcessResult result = await Process.run(
      _powerShellExecutable,
      <String>[
        '-NoProfile',
        '-File',
        'tool/build_windows.ps1',
        '-Flavor',
        'Production',
        '-SkipPreflight',
      ],
      workingDirectory: Directory.current.path,
      environment: environment,
    );

    expect(result.exitCode, isNot(0));
    expect(
      '${result.stdout}${result.stderr}',
      contains('signing credentials are missing'),
    );
  });

  test(
    'release evidence gate fails closed while required proof is pending',
    () async {
      final ProcessResult result =
          await Process.run(_powerShellExecutable, <String>[
            '-NoProfile',
            '-File',
            'tool/check_release_evidence.ps1',
            '-ReleaseTier',
            'Production',
          ], workingDirectory: Directory.current.path);

      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}${result.stderr}',
        contains('release evidence is incomplete'),
      );
    },
  );

  test('artifact manifests bind packages to the current source snapshot', () {
    final String verifier = File('tool/verify_artifact.ps1').readAsStringSync();
    final String evidenceGate = File(
      'tool/check_release_evidence.ps1',
    ).readAsStringSync();

    expect(verifier, contains(r'sourceSnapshotSha256 = $SourceSnapshot'));
    expect(
      verifier,
      contains('Manifest recording requires a lowercase source snapshot'),
    );
    expect(
      evidenceGate,
      contains('Artifact manifest does not match the current source snapshot'),
    );
    for (final String path in <String>[
      'tool/package_windows.ps1',
      'tool/package_android.ps1',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source, contains('Get-ClockRhythmSourceSnapshotSha256'));
      expect(source, contains('-SourceSnapshotSha256'));
    }
    expect(
      File('tool/source_snapshot.ps1').readAsStringSync(),
      contains('[System.StringComparer]::Ordinal'),
    );
    expect(
      File('tool/source_snapshot.ps1').readAsStringSync(),
      contains("'integration_test'"),
    );
    expect(
      File('tool/source_snapshot.ps1').readAsStringSync(),
      contains('GeneratedPluginRegistrant.java'),
    );
  });

  test('Android evidence harness judges adb by its real exit code', () {
    final String source = File(
      'tool/test_android_lifecycle.ps1',
    ).readAsStringSync();

    expect(source, contains("\$ErrorActionPreference = 'Continue'"));
    expect(source, contains(r'$exitCode = $LASTEXITCODE'));
    expect(source, contains('if (\$exitCode -ne 0)'));
  });

  test('Android release builds remove a dev-only generated registrant', () {
    final String cleanup = File(
      'tool/remove_stale_android_plugin_registrant.ps1',
    ).readAsStringSync();

    expect(cleanup, contains('GeneratedPluginRegistrant.java'));
    expect(cleanup, contains('Remove-Item -LiteralPath \$registrantPath'));
    for (final String path in <String>[
      'tool/build_android.ps1',
      'tool/package_android.ps1',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('remove_stale_android_plugin_registrant.ps1'),
      );
    }
  });

  test(
    'workflows preserve the lock before verification and rerun preflight',
    () {
      for (final String path in <String>[
        '.github/workflows/windows.yml',
        '.github/workflows/android.yml',
      ]) {
        final String source = File(path).readAsStringSync();
        expect(source, contains('--skip-pub-get'));
        expect(source, isNot(contains('-SkipPreflight')));
        expect(source, isNot(contains('\t')));
      }
      expect(
        File('tool/build_windows.ps1').readAsStringSync(),
        contains('--no-pub'),
      );
      expect(
        File('tool/verify.ps1').readAsStringSync(),
        contains('lib test integration_test tool'),
      );
      expect(
        File('tool/build_windows.ps1').readAsStringSync(),
        contains('test_windows_lifecycle.ps1'),
      );
      expect(
        File('tool/build_android.ps1').readAsStringSync(),
        contains('--no-pub'),
      );
      expect(
        File('tool/build_android.ps1').readAsStringSync(),
        contains(r'--flavor $flavorId'),
      );
      expect(
        File('tool/build_android.ps1').readAsStringSync(),
        contains(":app:testDebugUnitTest"),
      );
      expect(
        File('.github/workflows/android.yml').readAsStringSync(),
        contains('java-version: 25'),
      );
      expect(
        File('.github/workflows/windows.yml').readAsStringSync(),
        contains('package_windows.ps1 -Flavor Beta -Artifact Zip'),
      );
      expect(
        File('.github/workflows/android.yml').readAsStringSync(),
        contains('package_android.ps1 -Flavor Beta -Artifact Apk'),
      );
      expect(
        File('tool/build_windows.ps1').readAsStringSync(),
        contains('CLOCK_RHYTHM_WINDOWS_FLAVOR'),
      );
      expect(
        File('tool/build_windows.ps1').readAsStringSync(),
        contains(r'--build-name $buildName'),
      );
    },
  );
}

String get _powerShellExecutable => 'pwsh';

Future<File> _createFakeFvm({
  required Directory temporaryDirectory,
  required String bodyOnWindows,
  required String bodyOnPosix,
}) async {
  final File executable;
  if (Platform.isWindows) {
    executable = File('${temporaryDirectory.path}/fake-fvm.cmd');
    await executable.writeAsString('@echo off\r\n$bodyOnWindows');
  } else {
    executable = File('${temporaryDirectory.path}/fake-fvm');
    await executable.writeAsString('#!/usr/bin/env sh\n$bodyOnPosix');
    final ProcessResult chmod = await Process.run('chmod', <String>[
      '+x',
      executable.path,
    ]);
    if (chmod.exitCode != 0) {
      throw StateError('Unable to make fake FVM executable.');
    }
  }
  return executable;
}
