import 'dart:io';

import '../../../tool/check_architecture.dart';

final class ArchitectureFixture {
  ArchitectureFixture._({required this.workspace, required this.sourceRoot});

  final Directory workspace;
  final Directory sourceRoot;

  static ArchitectureFixture create() {
    final Directory workspace = Directory.systemTemp.createTempSync(
      'clock_rhythm_architecture_',
    );
    final Directory sourceRoot = Directory(
      '${workspace.path}${Platform.pathSeparator}lib',
    )..createSync();
    return ArchitectureFixture._(workspace: workspace, sourceRoot: sourceRoot);
  }

  void addFile(String relativePath, String content) {
    _writeFile(root: sourceRoot, relativePath: relativePath, content: content);
  }

  void addWorkspaceFile(String relativePath, String content) {
    _writeFile(root: workspace, relativePath: relativePath, content: content);
  }

  void _writeFile({
    required Directory root,
    required String relativePath,
    required String content,
  }) {
    final String platformPath = relativePath.replaceAll(
      '/',
      Platform.pathSeparator,
    );
    final File file = File(
      '${root.path}${Platform.pathSeparator}$platformPath',
    );
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  ArchitectureScanResult scan() {
    return ArchitectureScanner(sourceRoot: sourceRoot).scan();
  }

  void dispose() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  }
}

ArchitectureViolation violationFor(
  ArchitectureScanResult result, {
  required String ruleId,
  required String relativePath,
}) {
  return result.violations.singleWhere(
    (ArchitectureViolation violation) =>
        violation.ruleId == ruleId && violation.relativePath == relativePath,
  );
}
