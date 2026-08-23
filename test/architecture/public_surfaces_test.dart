import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_architecture.dart';
import 'support/architecture_fixture.dart';

void main() {
  test('declares only the planned minimal module entry points', () {
    const List<String> publicSurfacePaths = <String>[
      'lib/app/public.dart',
      'lib/contexts/preferences/public.dart',
      'lib/contexts/preferences/public_model.dart',
      'lib/contexts/preferences/public_presentation.dart',
      'lib/contexts/rhythm/public.dart',
      'lib/contexts/rhythm/public_model.dart',
      'lib/contexts/rhythm/public_presentation.dart',
      'lib/contexts/todo/public.dart',
      'lib/contexts/todo/public_model.dart',
      'lib/contexts/todo/public_presentation.dart',
      'lib/features/data_transfer/public.dart',
      'lib/features/data_transfer/public_presentation.dart',
      'lib/shared/i18n/public.dart',
      'lib/shared/time/public.dart',
      'lib/shared/ui/public.dart',
    ];

    for (final String path in publicSurfacePaths) {
      expect(File(path).existsSync(), isTrue, reason: '$path must exist');
    }

    final List<String> actualSurfacePaths =
        Directory('lib')
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .map((File file) => file.path.replaceAll('\\', '/'))
            .where(
              (String path) =>
                  path.split('/').last.startsWith('public') &&
                  path.endsWith('.dart'),
            )
            .toList(growable: false)
          ..sort();
    final List<String> expectedSurfacePaths = <String>[...publicSurfacePaths]
      ..sort();
    final List<String> catalogSurfacePaths =
        ArchitecturePublicSurfaceCatalog.paths
            .map((String path) => 'lib/$path')
            .toList(growable: false)
          ..sort();

    expect(actualSurfacePaths, expectedSurfacePaths);
    expect(catalogSurfacePaths, expectedSurfacePaths);
  });

  test('the production source tree satisfies its public surface contracts', () {
    final ArchitectureScanResult result = ArchitectureScanner(
      sourceRoot: Directory('lib'),
    ).scan();

    expect(result.violations, isEmpty);
  });

  test('allows the planned app-level platform presentation profile', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture.addFile(
      'app/platform_presentation_profile.dart',
      'enum PlatformPresentationProfile { windows, android }\n',
    );

    expect(fixture.scan().violations, isEmpty);
  });

  test('allows app-owned application ports for cross-platform composition', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture.addFile('app/application/ports/window_port.dart', 'library;\n');

    expect(fixture.scan().violations, isEmpty);
  });

  test('rejects infrastructure exported through a public barrel', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/public.dart';
    fixture
      ..addFile(
        sourcePath,
        "export 'infrastructure/drift_todo_repository.dart';\n",
      )
      ..addFile(
        'contexts/todo/infrastructure/drift_todo_repository.dart',
        'library;\n',
      );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.publicSurfaceExport,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
    expect(violation.toString(), contains('ARCH009 $sourcePath:1:'));
  });

  test('rejects declarations inside a public barrel', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/public.dart';
    fixture.addFile(sourcePath, 'final class LeakedTodoImplementation {}\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.publicSurfaceExport,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects part directives inside a public barrel', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/public.dart';
    fixture
      ..addFile(sourcePath, "part 'application/leaked_api.dart';\n")
      ..addFile(
        'contexts/todo/application/leaked_api.dart',
        "part of '../../public.dart';\n",
      );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.publicSurfaceExport,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects infrastructure hidden behind a presentation export', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/presentation/todo_api.dart';
    fixture
      ..addFile(
        'contexts/todo/public_presentation.dart',
        "export 'presentation/todo_api.dart';\n",
      )
      ..addFile(
        sourcePath,
        "export '../infrastructure/drift_todo_repository.dart';\n",
      )
      ..addFile(
        'contexts/todo/infrastructure/drift_todo_repository.dart',
        'library;\n',
      );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.publicSurfaceExport,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('does not treat unplanned public filenames as entry points', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'app/composition/bootstrap.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/shared/time/public_model.dart';\n",
      )
      ..addFile('shared/time/public_model.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.externalPublicSurface,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('lets shared i18n own generated localization output', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture
      ..addFile(
        'shared/i18n/public.dart',
        "export '../../l10n/generated/app_localizations.dart';\n",
      )
      ..addFile('l10n/generated/app_localizations.dart', 'library;\n');

    expect(fixture.scan().violations, isEmpty);
  });

  test('normalizes relative paths before enforcing deep imports', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/rhythm/application/read_todo.dart';
    fixture
      ..addFile(sourcePath, "import '../../todo/domain/todo.dart';\n")
      ..addFile('contexts/todo/domain/todo.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.externalPublicSurface,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects Data Transfer concrete and deep context dependencies', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'features/data_transfer/application/prepare_backup.dart';
    fixture
      ..addFile(
        sourcePath,
        "import '../../../contexts/todo/infrastructure/drift_todo_repository.dart';\n",
      )
      ..addFile(
        'contexts/todo/infrastructure/drift_todo_repository.dart',
        'library;\n',
      );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.dataTransferDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
    expect(violation.toString(), contains('ARCH006 $sourcePath:1:'));
  });

  test('rejects repository symbols imported through a context surface', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'features/data_transfer/application/prepare_backup.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/contexts/todo/public.dart' "
        'show DriftTodoRepository;\n',
      )
      ..addFile('contexts/todo/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.dataTransferDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('requires Data Transfer to narrow a context application import', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'features/data_transfer/application/prepare_backup.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/contexts/todo/public.dart';\n",
      )
      ..addFile('contexts/todo/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.dataTransferDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('allows Data Transfer to own a repository-named abstraction', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture.addFile(
      'features/data_transfer/application/backup_repository.dart',
      'abstract interface class BackupRepository {}\n'
          'final class ExportBackup {\n'
          '  const ExportBackup(this.backupRepository);\n'
          '  final BackupRepository backupRepository;\n'
          '}\n',
    );

    expect(fixture.scan().violations, isEmpty);
  });

  test('rejects Data Transfer depending on another feature', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'features/data_transfer/application/prepare_backup.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/features/reporting/public.dart';\n",
      )
      ..addFile('features/reporting/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.dataTransferDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('allows external consumers to use each declared entry-point kind', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture
      ..addFile('contexts/todo/public.dart', 'library;\n')
      ..addFile('contexts/todo/public_model.dart', 'library;\n')
      ..addFile('contexts/todo/public_presentation.dart', 'library;\n')
      ..addFile(
        'app/composition/bootstrap.dart',
        "import 'package:clock_rhythm/contexts/todo/public.dart';\n"
            "import 'package:clock_rhythm/contexts/todo/public_model.dart';\n"
            "import 'package:clock_rhythm/contexts/todo/public_presentation.dart';\n",
      );

    expect(fixture.scan().violations, isEmpty);
  });

  test('lets only app composition instantiate concrete module adapters', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture
      ..addFile(
        'app/composition/bootstrap.dart',
        "import 'package:clock_rhythm/features/data_transfer/infrastructure/json/backup_v1_codec.dart';\n",
      )
      ..addFile(
        'features/data_transfer/infrastructure/json/backup_v1_codec.dart',
        'library;\n',
      );

    expect(fixture.scan().violations, isEmpty);
  });

  test('keeps concrete module adapters hidden from app presentation', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'app/presentation/data_page.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/features/data_transfer/infrastructure/json/backup_v1_codec.dart';\n",
      )
      ..addFile(
        'features/data_transfer/infrastructure/json/backup_v1_codec.dart',
        'library;\n',
      );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.externalPublicSurface,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });
}
