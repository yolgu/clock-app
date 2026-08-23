import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_architecture.dart';
import 'support/architecture_fixture.dart';

void main() {
  test('rejects a deep import into Todo with rule, file, and line', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/rhythm/application/read_todo.dart';
    fixture
      ..addFile(
        sourcePath,
        "library;\n\nimport 'package:clock_rhythm/contexts/todo/domain/todo.dart';\n",
      )
      ..addFile('contexts/todo/domain/todo.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.externalPublicSurface,
      relativePath: sourcePath,
    );

    expect(violation.line, 3);
    expect(violation.toString(), contains('ARCH001 $sourcePath:3:'));
  });

  test('rejects Flutter from Domain with rule, file, and line', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture.addFile(
      sourcePath,
      "library;\nimport 'package:flutter/widgets.dart';\n",
    );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 2);
    expect(violation.toString(), contains('ARCH003 $sourcePath:2:'));
  });

  test('rejects an unclassified package from Domain by default', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture.addFile(
      sourcePath,
      "import 'package:future_platform_plugin/future_platform_plugin.dart';\n",
    );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('allows approved platform-neutral Dart libraries in Domain', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture.addFile('contexts/todo/domain/todo.dart', "import 'dart:math';\n");

    expect(fixture.scan().violations, isEmpty);
  });

  test('allows the approved grapheme package in Domain', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture.addFile(
      'contexts/todo/domain/title.dart',
      "import 'package:characters/characters.dart';\n"
          "int lengthOf(String value) => value.characters.length;\n",
    );

    expect(fixture.scan().violations, isEmpty);
  });

  test('rejects dart:ui from Domain', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture.addFile(sourcePath, "import 'dart:ui';\n");

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('checks aliased conditional import alternatives through the AST', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/rhythm/domain/rhythm_clock.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'clock_stub.dart'\n"
        "    if (dart.library.io) 'package:flutter/widgets.dart' as widgets;\n",
      )
      ..addFile('contexts/rhythm/domain/clock_stub.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 2);
    expect(violation.toString(), contains('ARCH003 $sourcePath:2:'));
  });

  test('rejects platform selection conditions from Domain', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/rhythm/domain/rhythm_clock.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'clock_stub.dart'\n"
        "    if (dart.library.io) 'clock_windows.dart';\n",
      )
      ..addFile('contexts/rhythm/domain/clock_stub.dart', 'library;\n')
      ..addFile('contexts/rhythm/domain/clock_windows.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.platformLeak,
      relativePath: sourcePath,
    );

    expect(violation.line, 2);
  });

  test('rejects platform selection conditions from Application exports', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/rhythm/application/clock_port.dart';
    fixture
      ..addFile(
        sourcePath,
        "export 'clock_stub.dart'\n"
        "    if (dart.library.io) 'clock_windows.dart';\n",
      )
      ..addFile('contexts/rhythm/application/clock_stub.dart', 'library;\n')
      ..addFile('contexts/rhythm/application/clock_windows.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.platformLeak,
      relativePath: sourcePath,
    );

    expect(violation.line, 2);
  });

  for (final String outwardLayer in <String>[
    'infrastructure',
    'presentation',
  ]) {
    test('rejects Application to $outwardLayer dependencies', () {
      final ArchitectureFixture fixture = ArchitectureFixture.create();
      addTearDown(fixture.dispose);
      const String sourcePath = 'contexts/todo/application/load_todos.dart';
      final String targetPath =
          'contexts/todo/$outwardLayer/todo_dependency.dart';
      fixture
        ..addFile(
          sourcePath,
          "import '../$outwardLayer/todo_dependency.dart';\n",
        )
        ..addFile(targetPath, 'library;\n');

      final ArchitectureViolation violation = violationFor(
        fixture.scan(),
        ruleId: ArchitectureRuleId.applicationDependency,
        relativePath: sourcePath,
      );

      expect(violation.line, 1);
      expect(violation.toString(), contains('ARCH004 $sourcePath:1:'));
    });
  }

  test('rejects Domain importing its Application public barrel', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture
      ..addFile(sourcePath, "import '../public.dart';\n")
      ..addFile('contexts/todo/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects Domain importing its Presentation public barrel', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture
      ..addFile(sourcePath, "import '../public_presentation.dart';\n")
      ..addFile('contexts/todo/public_presentation.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects Application importing its Presentation public barrel', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/application/load_todos.dart';
    fixture
      ..addFile(sourcePath, "import '../public_presentation.dart';\n")
      ..addFile('contexts/todo/public_presentation.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.applicationDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects a business module importing generated l10n directly', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/l10n/generated/app_localizations.dart';\n",
      )
      ..addFile('l10n/generated/app_localizations.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.externalPublicSurface,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects Domain importing presentation-facing shared i18n', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/shared/i18n/public.dart';\n",
      )
      ..addFile(
        'shared/i18n/public.dart',
        "export '../../l10n/generated/app_localizations.dart';\n",
      )
      ..addFile(
        'l10n/generated/app_localizations.dart',
        "import 'package:flutter/widgets.dart';\n",
      );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects Application importing presentation-facing shared UI', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/application/load_todos.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/shared/ui/public.dart';\n",
      )
      ..addFile('shared/ui/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.applicationDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects a relative import that escapes the source root', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/domain/todo.dart';
    fixture
      ..addFile(sourcePath, "import '../../../../shared/time/public.dart';\n")
      ..addWorkspaceFile('shared/time/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.domainDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects a business module importing the root entry point', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/application/load_todos.dart';
    fixture
      ..addFile(sourcePath, "import 'package:clock_rhythm/main.dart';\n")
      ..addFile('main.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.externalPublicSurface,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects context code outside a declared layer', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/internal/todo.dart';
    fixture.addFile(sourcePath, 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.moduleLayout,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('allows app configuration as an app-owned application contract', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture
      ..addFile('app/config/app_flavor.dart', 'library;\n')
      ..addFile(
        'app/composition/bootstrap.dart',
        "import '../config/app_flavor.dart';\n",
      );

    expect(fixture.scan().violations, isEmpty);
  });

  test('rejects a context dependency on app composition', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'contexts/preferences/application/load_preferences.dart';
    fixture
      ..addFile(sourcePath, "import 'package:clock_rhythm/app/public.dart';\n")
      ..addFile('app/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.compositionDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
    expect(violation.toString(), contains('ARCH002 $sourcePath:1:'));
  });

  test('rejects Rhythm depending on Preferences public contracts', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/rhythm/application/start_rhythm.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/contexts/preferences/public.dart';\n",
      )
      ..addFile('contexts/preferences/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.contextDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
    expect(violation.toString(), contains('ARCH008 $sourcePath:1:'));
  });

  test('rejects platform checks from ViewModel-like presentation files', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'contexts/rhythm/presentation/rhythm_view_model.dart';
    fixture.addFile(
      sourcePath,
      "import 'dart:io';\n\nbool get isWindows => Platform.isWindows;\n",
    );

    final ArchitectureScanResult result = fixture.scan();
    final List<ArchitectureViolation> violations = result.violations
        .where(
          (ArchitectureViolation violation) =>
              violation.ruleId == ArchitectureRuleId.platformLeak &&
              violation.relativePath == sourcePath,
        )
        .toList(growable: false);

    expect(
      violations.map((ArchitectureViolation violation) => violation.line),
      containsAll(<int>[1, 3]),
    );
  });

  test('rejects an unclassified package from a ViewModel', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'contexts/rhythm/presentation/rhythm_view_model.dart';
    fixture.addFile(
      sourcePath,
      "import 'package:future_platform_plugin/future_platform_plugin.dart';\n",
    );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.platformLeak,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects Infrastructure depending on Presentation', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath =
        'contexts/todo/infrastructure/drift_todo_repository.dart';
    fixture
      ..addFile(sourcePath, "import '../presentation/todo_page.dart';\n")
      ..addFile('contexts/todo/presentation/todo_page.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.infrastructureDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects Presentation depending on Infrastructure', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'contexts/todo/presentation/todo_page.dart';
    fixture
      ..addFile(
        sourcePath,
        "import '../infrastructure/drift_todo_repository.dart';\n",
      )
      ..addFile(
        'contexts/todo/infrastructure/drift_todo_repository.dart',
        'library;\n',
      );

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.presentationDependency,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('allows inward own-layer and declared public dependencies', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture
      ..addFile('contexts/todo/domain/todo.dart', 'library;\n')
      ..addFile('shared/time/public.dart', 'library;\n')
      ..addFile(
        'contexts/todo/application/load_todos.dart',
        "import '../domain/todo.dart';\n"
            "import 'package:clock_rhythm/shared/time/public.dart';\n",
      )
      ..addFile('contexts/todo/public.dart', 'library;\n')
      ..addFile('contexts/rhythm/public_model.dart', 'library;\n')
      ..addFile(
        'contexts/preferences/domain/user_preferences.dart',
        "import 'package:clock_rhythm/contexts/rhythm/public_model.dart';\n",
      )
      ..addFile('contexts/preferences/public_model.dart', 'library;\n')
      ..addFile('features/data_transfer/public.dart', 'library;\n')
      ..addFile(
        'features/data_transfer/application/prepare_backup.dart',
        "import 'package:clock_rhythm/contexts/preferences/public_model.dart';\n"
            "import 'package:clock_rhythm/contexts/todo/public.dart' "
            'show ExportTodoSnapshots;\n',
      )
      ..addFile(
        'app/composition/bootstrap.dart',
        "import 'package:clock_rhythm/contexts/todo/public.dart';\n"
            "import 'package:clock_rhythm/features/data_transfer/public.dart';\n",
      );

    expect(fixture.scan().violations, isEmpty);
  });
}
