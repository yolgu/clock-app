import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_architecture.dart';
import 'support/architecture_fixture.dart';

void main() {
  test('rejects shared importing Preferences with rule, file, and line', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'shared/time/system_clock.dart';
    fixture
      ..addFile(
        sourcePath,
        "library;\nimport 'package:clock_rhythm/contexts/preferences/public.dart';\n",
      )
      ..addFile('contexts/preferences/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.sharedPurity,
      relativePath: sourcePath,
    );

    expect(violation.line, 2);
    expect(violation.toString(), contains('ARCH005 $sourcePath:2:'));
  });

  test('requires public entry points between shared modules', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'shared/ui/adaptive_layout.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/shared/i18n/local_formatter.dart';\n",
      )
      ..addFile('shared/i18n/local_formatter.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.externalPublicSurface,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('rejects shared time depending on presentation-facing shared UI', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    const String sourcePath = 'shared/time/system_clock.dart';
    fixture
      ..addFile(
        sourcePath,
        "import 'package:clock_rhythm/shared/ui/public.dart';\n",
      )
      ..addFile('shared/ui/public.dart', 'library;\n');

    final ArchitectureViolation violation = violationFor(
      fixture.scan(),
      ruleId: ArchitectureRuleId.sharedPurity,
      relativePath: sourcePath,
    );

    expect(violation.line, 1);
  });

  test('allows shared i18n to depend inward on shared time', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture
      ..addFile('shared/time/public.dart', 'library;\n')
      ..addFile(
        'shared/i18n/local_date_formatter.dart',
        "import 'package:clock_rhythm/shared/time/public.dart';\n",
      );

    expect(fixture.scan().violations, isEmpty);
  });

  test('allows shared-to-shared public and UI framework dependencies', () {
    final ArchitectureFixture fixture = ArchitectureFixture.create();
    addTearDown(fixture.dispose);
    fixture
      ..addFile('shared/i18n/public.dart', 'library;\n')
      ..addFile(
        'shared/ui/adaptive_layout.dart',
        "import 'package:flutter/widgets.dart';\n"
            "import 'package:clock_rhythm/shared/i18n/public.dart';\n",
      );

    expect(fixture.scan().violations, isEmpty);
  });
}
