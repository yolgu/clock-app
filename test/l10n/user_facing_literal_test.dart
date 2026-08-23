import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps translated Korean text out of domain and application source', () {
    final List<String> violations =
        _dartFilesUnder(
              <String>['lib/contexts', 'lib/features'],
              pathSegments: <String>{'domain', 'application'},
            )
            .where(
              (File file) =>
                  RegExp(r'[\uac00-\ud7a3]').hasMatch(file.readAsStringSync()),
            )
            .map((File file) => file.path)
            .toList(growable: false);

    expect(
      violations,
      isEmpty,
      reason:
          'Domain and Application must expose stable codes, not translated copy.',
    );
  });

  test('keeps direct user-facing literals out of presentation widgets', () {
    final RegExp directText = RegExp(
      r'''\b(?:Text|SelectableText)\s*\(\s*(['"])([^'"]+)\1''',
      multiLine: true,
    );
    final RegExp namedUserCopy = RegExp(
      r'''\b(?:semanticLabel|tooltip|label|hint|labelText|hintText|helperText|errorText|message)\s*:\s*(['"])([^'"]+)\1''',
      multiLine: true,
    );
    final List<String> violations = <String>[];

    for (final File file in _presentationFiles()) {
      final String source = file.readAsStringSync();
      for (final RegExp pattern in <RegExp>[directText, namedUserCopy]) {
        for (final RegExpMatch match in pattern.allMatches(source)) {
          violations.add('${file.path}: ${match.group(2)}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Presentation copy must come from AppLocalizations.',
    );
  });
}

Iterable<File> _presentationFiles() {
  return _dartFilesUnder(
    <String>['lib/app/presentation', 'lib/contexts', 'lib/features'],
    pathSegments: <String>{'presentation'},
  );
}

Iterable<File> _dartFilesUnder(
  List<String> roots, {
  required Set<String> pathSegments,
}) sync* {
  for (final String root in roots) {
    final Directory directory = Directory(root);
    if (!directory.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final Set<String> segments = entity.path
          .replaceAll('\\', '/')
          .split('/')
          .toSet();
      if (segments.intersection(pathSegments).isNotEmpty) {
        yield entity;
      }
    }
  }
}
