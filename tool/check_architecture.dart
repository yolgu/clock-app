import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';

abstract final class ArchitectureRuleId {
  static const String parseError = 'ARCH000';
  static const String externalPublicSurface = 'ARCH001';
  static const String compositionDependency = 'ARCH002';
  static const String domainDependency = 'ARCH003';
  static const String applicationDependency = 'ARCH004';
  static const String sharedPurity = 'ARCH005';
  static const String dataTransferDependency = 'ARCH006';
  static const String platformLeak = 'ARCH007';
  static const String contextDependency = 'ARCH008';
  static const String publicSurfaceExport = 'ARCH009';
  static const String infrastructureDependency = 'ARCH010';
  static const String presentationDependency = 'ARCH011';
  static const String moduleLayout = 'ARCH012';
}

abstract final class ArchitecturePublicSurfaceCatalog {
  static const Map<String, Set<String>> byModule = <String, Set<String>>{
    'app': <String>{'app/public.dart'},
    'contexts/preferences': <String>{
      'contexts/preferences/public.dart',
      'contexts/preferences/public_model.dart',
      'contexts/preferences/public_presentation.dart',
    },
    'contexts/rhythm': <String>{
      'contexts/rhythm/public.dart',
      'contexts/rhythm/public_model.dart',
      'contexts/rhythm/public_presentation.dart',
    },
    'contexts/todo': <String>{
      'contexts/todo/public.dart',
      'contexts/todo/public_model.dart',
      'contexts/todo/public_presentation.dart',
    },
    'features/data_transfer': <String>{
      'features/data_transfer/public.dart',
      'features/data_transfer/public_presentation.dart',
    },
    'shared/i18n': <String>{'shared/i18n/public.dart'},
    'shared/time': <String>{'shared/time/public.dart'},
    'shared/ui': <String>{'shared/ui/public.dart'},
  };

  static Set<String> get paths => Set<String>.unmodifiable(
    byModule.values.expand((Set<String> paths) => paths),
  );

  static bool contains({
    required String moduleId,
    required String relativePath,
  }) {
    return byModule[moduleId]?.contains(relativePath) ?? false;
  }
}

final class ArchitectureViolation {
  const ArchitectureViolation({
    required this.ruleId,
    required this.relativePath,
    required this.line,
    required this.column,
    required this.message,
  });

  final String ruleId;
  final String relativePath;
  final int line;
  final int column;
  final String message;

  @override
  String toString() {
    return '$ruleId $relativePath:$line:$column $message';
  }
}

final class ArchitectureScanResult {
  ArchitectureScanResult({
    required this.scannedFileCount,
    required List<ArchitectureViolation> violations,
  }) : violations = List<ArchitectureViolation>.unmodifiable(violations);

  final int scannedFileCount;
  final List<ArchitectureViolation> violations;

  bool get hasViolations => violations.isNotEmpty;
}

final class ArchitectureScanner {
  ArchitectureScanner({
    required Directory sourceRoot,
    this.packageName = 'clock_rhythm',
  }) : sourceRoot = sourceRoot.absolute {
    if (packageName.isEmpty) {
      throw ArgumentError.value(
        packageName,
        'packageName',
        'must not be empty',
      );
    }
  }

  final Directory sourceRoot;
  final String packageName;

  ArchitectureScanResult scan() {
    if (!sourceRoot.existsSync()) {
      throw FileSystemException(
        'Architecture source root does not exist',
        sourceRoot.path,
      );
    }

    final List<File> sourceFiles =
        sourceRoot
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))
            .toList(growable: false)
          ..sort((File left, File right) => left.path.compareTo(right.path));
    final List<ArchitectureViolation> violations = <ArchitectureViolation>[];
    final Set<String> violationKeys = <String>{};

    for (final File sourceFile in sourceFiles) {
      _scanFile(sourceFile, violations, violationKeys);
    }

    violations.sort(_compareViolations);
    return ArchitectureScanResult(
      scannedFileCount: sourceFiles.length,
      violations: violations,
    );
  }

  void _scanFile(
    File sourceFile,
    List<ArchitectureViolation> violations,
    Set<String> violationKeys,
  ) {
    final String relativePath = _relativePath(sourceFile);
    final String content = sourceFile.readAsStringSync();
    final ParseStringResult parsed = parseString(
      content: content,
      path: sourceFile.path,
      throwIfDiagnostics: false,
    );
    final _ArchitectureFile architectureFile = _ArchitectureFile(
      relativePath: relativePath,
      module: _ModuleLocation.fromPath(relativePath),
      unit: parsed.unit,
      lineInfo: parsed.lineInfo,
    );

    _checkModuleLocation(
      source: architectureFile,
      violations: violations,
      violationKeys: violationKeys,
    );
    _checkPublicSurfaceShape(
      source: architectureFile,
      violations: violations,
      violationKeys: violationKeys,
    );

    for (final Diagnostic diagnostic in parsed.errors) {
      _addViolation(
        source: architectureFile,
        ruleId: ArchitectureRuleId.parseError,
        offset: diagnostic.offset,
        message: diagnostic.message.replaceAll(RegExp(r'\s+'), ' '),
        violations: violations,
        violationKeys: violationKeys,
      );
    }

    for (final Directive directive in parsed.unit.directives) {
      final List<Combinator> combinators = directive is NamespaceDirective
          ? directive.combinators.toList(growable: false)
          : const <Combinator>[];
      if (directive is UriBasedDirective) {
        _checkUriReference(
          source: architectureFile,
          uriLiteral: directive.uri,
          isExport: directive is ExportDirective,
          combinators: combinators,
          violations: violations,
          violationKeys: violationKeys,
        );
      }

      if (directive is NamespaceDirective) {
        for (final Configuration configuration in directive.configurations) {
          _checkPlatformConfiguration(
            source: architectureFile,
            configuration: configuration,
            violations: violations,
            violationKeys: violationKeys,
          );
          _checkUriReference(
            source: architectureFile,
            uriLiteral: configuration.uri,
            isExport: directive is ExportDirective,
            combinators: combinators,
            violations: violations,
            violationKeys: violationKeys,
          );
        }
      }
    }

    if (_isPlatformRestrictedFile(architectureFile)) {
      parsed.unit.accept(
        _PlatformIdentifierVisitor(
          onPlatformIdentifier: (SimpleIdentifier identifier) {
            _addViolation(
              source: architectureFile,
              ruleId: ArchitectureRuleId.platformLeak,
              offset: identifier.offset,
              message:
                  'Platform check or type "${identifier.name}" is not allowed '
                  'in this layer.',
              violations: violations,
              violationKeys: violationKeys,
            );
          },
        ),
      );
    }
  }

  void _checkModuleLocation({
    required _ArchitectureFile source,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    if (_isAllowedModuleLocation(source)) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.moduleLayout,
      offset: 0,
      message:
          'Source files must live in a declared module and layer; '
          '"${source.relativePath}" is outside the approved layout.',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  void _checkPublicSurfaceShape({
    required _ArchitectureFile source,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ModuleLocation? module = source.module;
    if (module == null || !module.isPublicEntryPoint(source.relativePath)) {
      return;
    }

    for (final CompilationUnitMember declaration in source.unit.declarations) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.publicSurfaceExport,
        offset: declaration.offset,
        message: 'Public entry points must be export-only barrels.',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
    for (final Directive directive in source.unit.directives) {
      if (directive is! ImportDirective &&
          directive is! PartDirective &&
          directive is! PartOfDirective) {
        continue;
      }
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.publicSurfaceExport,
        offset: directive.offset,
        message:
            'Public entry points may contain only library and export '
            'directives.',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
  }

  void _checkPlatformConfiguration({
    required _ArchitectureFile source,
    required Configuration configuration,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    if (!_isPlatformRestrictedFile(source)) {
      return;
    }

    final String conditionName = configuration.name.tokens
        .map((token) => token.lexeme)
        .join();
    if (!conditionName.startsWith('dart.library.')) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.platformLeak,
      offset: configuration.name.offset,
      message:
          'Platform selection condition "$conditionName" is not allowed '
          'in this layer.',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  void _checkUriReference({
    required _ArchitectureFile source,
    required StringLiteral uriLiteral,
    required bool isExport,
    required List<Combinator> combinators,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final String? rawUri = uriLiteral.stringValue;
    if (rawUri == null) {
      return;
    }

    final String? targetPath = _resolveInternalPath(
      source.relativePath,
      rawUri,
    );
    final _ModuleLocation? targetModule = targetPath == null
        ? null
        : _ModuleLocation.fromPath(targetPath);

    if (targetPath != null && targetModule != null) {
      _checkPublicSurface(
        source: source,
        targetPath: targetPath,
        targetModule: targetModule,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        violations: violations,
        violationKeys: violationKeys,
      );
      _checkCompositionOwnership(
        source: source,
        targetModule: targetModule,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        violations: violations,
        violationKeys: violationKeys,
      );
      _checkContextDependency(
        source: source,
        targetPath: targetPath,
        targetModule: targetModule,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        violations: violations,
        violationKeys: violationKeys,
      );
      _checkSharedPurity(
        source: source,
        targetModule: targetModule,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        violations: violations,
        violationKeys: violationKeys,
      );
      _checkDataTransferDependency(
        source: source,
        targetPath: targetPath,
        targetModule: targetModule,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        isExport: isExport,
        combinators: combinators,
        violations: violations,
        violationKeys: violationKeys,
      );
      _checkLayerDependency(
        source: source,
        targetPath: targetPath,
        targetModule: targetModule,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        violations: violations,
        violationKeys: violationKeys,
      );
      if (isExport) {
        _checkExportDependency(
          source: source,
          targetPath: targetPath,
          targetModule: targetModule,
          uriLiteral: uriLiteral,
          rawUri: rawUri,
          violations: violations,
          violationKeys: violationKeys,
        );
        _checkPublicSurfaceExport(
          source: source,
          targetPath: targetPath,
          targetModule: targetModule,
          uriLiteral: uriLiteral,
          rawUri: rawUri,
          violations: violations,
          violationKeys: violationKeys,
        );
      }
    } else if (targetPath != null) {
      _checkUnownedInternalDependency(
        source: source,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        violations: violations,
        violationKeys: violationKeys,
      );
      if (isExport) {
        _checkExternalExport(
          source: source,
          uriLiteral: uriLiteral,
          rawUri: rawUri,
          violations: violations,
          violationKeys: violationKeys,
        );
      }
    } else {
      _checkExternalLayerDependency(
        source: source,
        uriLiteral: uriLiteral,
        rawUri: rawUri,
        violations: violations,
        violationKeys: violationKeys,
      );
      if (isExport) {
        _checkExternalExport(
          source: source,
          uriLiteral: uriLiteral,
          rawUri: rawUri,
          violations: violations,
          violationKeys: violationKeys,
        );
      }
    }

    if (_isPlatformRestrictedFile(source) &&
        _isForbiddenPlatformDependency(
          source: source,
          rawUri: rawUri,
          isInternal: targetPath != null,
        )) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.platformLeak,
        offset: uriLiteral.offset,
        message: 'Platform dependency "$rawUri" is not allowed in this file.',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
  }

  void _checkPublicSurface({
    required _ArchitectureFile source,
    required String targetPath,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    if (source.module?.id == targetModule.id ||
        targetModule.isPublicEntryPoint(targetPath) ||
        _isCompositionAdapterEdge(source: source, targetModule: targetModule)) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.externalPublicSurface,
      offset: uriLiteral.offset,
      message:
          'External module dependency "$rawUri" must use a module-root '
          'public.dart, public_model.dart, or public_presentation.dart.',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  bool _isCompositionAdapterEdge({
    required _ArchitectureFile source,
    required _ModuleLocation targetModule,
  }) {
    return source.module?.kind == _ModuleKind.app &&
        source.relativePath.startsWith('app/composition/') &&
        targetModule.layer == _ArchitecturalLayer.infrastructure;
  }

  void _checkUnownedInternalDependency({
    required _ArchitectureFile source,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    if (source.module == null) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.externalPublicSurface,
      offset: uriLiteral.offset,
      message:
          'Owned module dependency "$rawUri" targets an unowned internal '
          'path.',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  void _checkExternalExport({
    required _ArchitectureFile source,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    if (source.module == null) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.publicSurfaceExport,
      offset: uriLiteral.offset,
      message: 'Owned modules cannot re-export external path "$rawUri".',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  void _checkCompositionOwnership({
    required _ArchitectureFile source,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ModuleKind? sourceKind = source.module?.kind;
    if ((sourceKind == _ModuleKind.context ||
            sourceKind == _ModuleKind.feature) &&
        targetModule.kind == _ModuleKind.app) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.compositionDependency,
        offset: uriLiteral.offset,
        message:
            'Contexts and features cannot depend on app composition '
            'through "$rawUri".',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
  }

  void _checkContextDependency({
    required _ArchitectureFile source,
    required String targetPath,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ModuleLocation? sourceModule = source.module;
    if (sourceModule == null ||
        sourceModule.kind != _ModuleKind.context ||
        sourceModule.id == targetModule.id) {
      return;
    }

    if (targetModule.kind == _ModuleKind.context &&
        _isPreferencesRhythmModelEdge(
          sourceModule: sourceModule,
          targetModule: targetModule,
          targetPath: targetPath,
        )) {
      return;
    }

    if (targetModule.kind == _ModuleKind.context ||
        targetModule.kind == _ModuleKind.feature) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.contextDependency,
        offset: uriLiteral.offset,
        message:
            'Context dependency "$rawUri" is not part of the allowed context '
            'map.',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
  }

  void _checkSharedPurity({
    required _ArchitectureFile source,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ModuleLocation? sourceModule = source.module;
    if (sourceModule == null || sourceModule.kind != _ModuleKind.shared) {
      return;
    }

    final bool businessDependency =
        targetModule.kind == _ModuleKind.app ||
        targetModule.kind == _ModuleKind.context ||
        targetModule.kind == _ModuleKind.feature;
    final bool invalidSharedDependency =
        targetModule.kind == _ModuleKind.shared &&
        sourceModule.id != targetModule.id &&
        !_isAllowedSharedDependency(
          sourceModuleId: sourceModule.id,
          targetModuleId: targetModule.id,
        );
    if (!businessDependency && !invalidSharedDependency) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.sharedPurity,
      offset: uriLiteral.offset,
      message: 'Shared dependency "$rawUri" is outside the allowed map.',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  void _checkDataTransferDependency({
    required _ArchitectureFile source,
    required String targetPath,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required bool isExport,
    required List<Combinator> combinators,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    if (source.module?.id != _dataTransferModuleId ||
        targetModule.id == _dataTransferModuleId ||
        targetModule.kind == _ModuleKind.shared) {
      return;
    }

    final String targetBaseName = _baseName(targetPath);
    final bool allowedContext =
        targetModule.kind == _ModuleKind.context &&
        const <String>{
          _preferencesModuleId,
          _todoModuleId,
        }.contains(targetModule.id);
    final bool allowedSurface =
        targetModule.isPublicEntryPoint(targetPath) &&
        (targetBaseName == 'public.dart' ||
            targetBaseName == 'public_model.dart');
    final bool narrowedApplicationSurface =
        targetBaseName != 'public.dart' ||
        _usesOnlyPublishedDataTransferContracts(combinators);

    if (!allowedContext ||
        !allowedSurface ||
        isExport ||
        !narrowedApplicationSurface) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.dataTransferDependency,
        offset: uriLiteral.offset,
        message:
            'Data Transfer may use only Preferences/Todo public snapshot and '
            'use-case contracts; "$rawUri" is not allowed.',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
  }

  bool _usesOnlyPublishedDataTransferContracts(List<Combinator> combinators) {
    ShowCombinator? showCombinator;
    for (final Combinator combinator in combinators) {
      if (combinator is ShowCombinator) {
        showCombinator = combinator;
        break;
      }
    }
    if (showCombinator == null) {
      return false;
    }

    return showCombinator.shownNames.every(
      (SimpleIdentifier identifier) =>
          !_isDataTransferInfrastructureContract(identifier.name),
    );
  }

  void _checkLayerDependency({
    required _ArchitectureFile source,
    required String targetPath,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ArchitecturalLayer? sourceLayer = source.policyLayer;
    final _ArchitecturalLayer? targetLayer = _policyLayerFor(
      module: targetModule,
      relativePath: targetPath,
    );
    final _ModuleLocation? sourceModule = source.module;
    final bool innerBusinessLayer =
        (sourceModule?.kind == _ModuleKind.context ||
            sourceModule?.kind == _ModuleKind.feature) &&
        (sourceLayer == _ArchitecturalLayer.domain ||
            sourceLayer == _ArchitecturalLayer.application);
    if (innerBusinessLayer &&
        targetModule.kind == _ModuleKind.shared &&
        targetModule.id != _sharedTimeModuleId) {
      _addViolation(
        source: source,
        ruleId: sourceLayer == _ArchitecturalLayer.domain
            ? ArchitectureRuleId.domainDependency
            : ArchitectureRuleId.applicationDependency,
        offset: uriLiteral.offset,
        message:
            'Inner layers may use only shared/time; "$rawUri" is '
            'presentation-facing.',
        violations: violations,
        violationKeys: violationKeys,
      );
    }

    final bool sameModule = sourceModule?.id == targetModule.id;
    if (!sameModule) {
      return;
    }

    if (sourceLayer == _ArchitecturalLayer.domain &&
        _domainOutwardLayers.contains(targetLayer)) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.domainDependency,
        offset: uriLiteral.offset,
        message: 'Domain cannot depend on outward layer "$rawUri".',
        violations: violations,
        violationKeys: violationKeys,
      );
    }

    if (sourceLayer == _ArchitecturalLayer.application &&
        _applicationOutwardLayers.contains(targetLayer)) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.applicationDependency,
        offset: uriLiteral.offset,
        message: 'Application cannot depend on outward layer "$rawUri".',
        violations: violations,
        violationKeys: violationKeys,
      );
    }

    if (sourceLayer == _ArchitecturalLayer.infrastructure &&
        targetLayer == _ArchitecturalLayer.presentation) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.infrastructureDependency,
        offset: uriLiteral.offset,
        message: 'Infrastructure cannot depend on Presentation "$rawUri".',
        violations: violations,
        violationKeys: violationKeys,
      );
    }

    if (sourceLayer == _ArchitecturalLayer.presentation &&
        targetLayer == _ArchitecturalLayer.infrastructure) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.presentationDependency,
        offset: uriLiteral.offset,
        message: 'Presentation cannot depend on Infrastructure "$rawUri".',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
  }

  void _checkExportDependency({
    required _ArchitectureFile source,
    required String targetPath,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ModuleLocation? sourceModule = source.module;
    if (sourceModule == null) {
      return;
    }

    final _ArchitecturalLayer? sourceLayer = source.policyLayer;
    final _ArchitecturalLayer? targetLayer = _policyLayerFor(
      module: targetModule,
      relativePath: targetPath,
    );
    final bool foreignModule = sourceModule.id != targetModule.id;
    final bool presentationLeak =
        sourceLayer == _ArchitecturalLayer.presentation &&
        targetLayer != _ArchitecturalLayer.presentation;
    final bool infrastructureLeak =
        sourceLayer == _ArchitecturalLayer.infrastructure &&
        targetLayer != _ArchitecturalLayer.infrastructure;
    if (!foreignModule && !presentationLeak && !infrastructureLeak) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.publicSurfaceExport,
      offset: uriLiteral.offset,
      message: 'Owned implementation cannot re-export "$rawUri".',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  void _checkExternalLayerDependency({
    required _ArchitectureFile source,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ArchitecturalLayer? sourceLayer = source.policyLayer;
    if (sourceLayer != _ArchitecturalLayer.domain &&
        sourceLayer != _ArchitecturalLayer.application) {
      return;
    }
    if (_isApprovedInnerLayerExternalDependency(rawUri)) {
      return;
    }

    if (sourceLayer == _ArchitecturalLayer.domain) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.domainDependency,
        offset: uriLiteral.offset,
        message: 'Domain cannot depend on external dependency "$rawUri".',
        violations: violations,
        violationKeys: violationKeys,
      );
    }

    if (sourceLayer == _ArchitecturalLayer.application) {
      _addViolation(
        source: source,
        ruleId: ArchitectureRuleId.applicationDependency,
        offset: uriLiteral.offset,
        message: 'Application cannot depend on external dependency "$rawUri".',
        violations: violations,
        violationKeys: violationKeys,
      );
    }
  }

  void _checkPublicSurfaceExport({
    required _ArchitectureFile source,
    required String targetPath,
    required _ModuleLocation targetModule,
    required StringLiteral uriLiteral,
    required String rawUri,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final _ModuleLocation? sourceModule = source.module;
    if (sourceModule == null ||
        !sourceModule.isPublicEntryPoint(source.relativePath)) {
      return;
    }

    final String sourceBaseName = _baseName(source.relativePath);
    final bool foreignModule = sourceModule.id != targetModule.id;
    final bool infrastructureExport =
        targetModule.layer == _ArchitecturalLayer.infrastructure;
    final bool invalidModelExport =
        sourceBaseName == 'public_model.dart' &&
        targetModule.layer != _ArchitecturalLayer.domain;
    final bool invalidPresentationExport =
        sourceBaseName == 'public_presentation.dart' &&
        targetModule.layer != _ArchitecturalLayer.presentation;
    final bool presentationThroughGeneralContextSurface =
        sourceBaseName == 'public.dart' &&
        (sourceModule.kind == _ModuleKind.context ||
            sourceModule.kind == _ModuleKind.feature) &&
        (targetModule.layer == _ArchitecturalLayer.presentation ||
            _baseName(targetPath) == 'public_presentation.dart');

    if (!foreignModule &&
        !infrastructureExport &&
        !invalidModelExport &&
        !invalidPresentationExport &&
        !presentationThroughGeneralContextSurface) {
      return;
    }

    _addViolation(
      source: source,
      ruleId: ArchitectureRuleId.publicSurfaceExport,
      offset: uriLiteral.offset,
      message: 'Public surface ${source.relativePath} cannot export "$rawUri".',
      violations: violations,
      violationKeys: violationKeys,
    );
  }

  void _addViolation({
    required _ArchitectureFile source,
    required String ruleId,
    required int offset,
    required String message,
    required List<ArchitectureViolation> violations,
    required Set<String> violationKeys,
  }) {
    final CharacterLocation location = source.lineInfo.getLocation(offset);
    final String key =
        '$ruleId|${source.relativePath}|${location.lineNumber}|'
        '${location.columnNumber}';
    if (!violationKeys.add(key)) {
      return;
    }

    violations.add(
      ArchitectureViolation(
        ruleId: ruleId,
        relativePath: source.relativePath,
        line: location.lineNumber,
        column: location.columnNumber,
        message: message,
      ),
    );
  }

  String _relativePath(File sourceFile) {
    final String normalizedRoot = _normalizeFileSystemPath(sourceRoot.path);
    final String normalizedFile = _normalizeFileSystemPath(
      sourceFile.absolute.path,
    );
    final String rootPrefix = normalizedRoot.endsWith('/')
        ? normalizedRoot
        : '$normalizedRoot/';
    if (!normalizedFile.toLowerCase().startsWith(rootPrefix.toLowerCase())) {
      throw StateError('${sourceFile.path} is outside ${sourceRoot.path}.');
    }
    return normalizedFile.substring(rootPrefix.length);
  }

  String? _resolveInternalPath(String sourcePath, String rawUri) {
    final Uri? parsedUri = Uri.tryParse(rawUri);
    if (parsedUri == null) {
      return null;
    }

    if (parsedUri.scheme == 'package') {
      final List<String> segments = parsedUri.pathSegments;
      if (segments.isEmpty || segments.first != packageName) {
        return null;
      }
      return _normalizeInternalSegments(segments.skip(1));
    }

    if (parsedUri.scheme.isNotEmpty || rawUri.startsWith('/')) {
      return null;
    }

    final List<String> sourceDirectorySegments = sourcePath.split('/')
      ..removeLast();
    return _normalizeInternalSegments(<String>[
      ...sourceDirectorySegments,
      ...parsedUri.pathSegments,
    ]);
  }
}

final class _ArchitectureFile {
  const _ArchitectureFile({
    required this.relativePath,
    required this.module,
    required this.unit,
    required this.lineInfo,
  });

  final String relativePath;
  final _ModuleLocation? module;
  final CompilationUnit unit;
  final LineInfo lineInfo;

  _ArchitecturalLayer? get policyLayer =>
      _policyLayerFor(module: module, relativePath: relativePath);
}

enum _ModuleKind { app, context, feature, shared }

enum _ArchitecturalLayer { domain, application, infrastructure, presentation }

final class _ModuleLocation {
  const _ModuleLocation({
    required this.id,
    required this.kind,
    required this.layer,
  });

  final String id;
  final _ModuleKind kind;
  final _ArchitecturalLayer? layer;

  static _ModuleLocation? fromPath(String relativePath) {
    final List<String> segments = relativePath
        .split('/')
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return null;
    }

    if (segments.first == 'l10n' &&
        segments.length >= 3 &&
        segments[1] == 'generated') {
      return const _ModuleLocation(
        id: 'shared/i18n',
        kind: _ModuleKind.shared,
        layer: null,
      );
    }

    if (segments.first == 'app') {
      return _ModuleLocation(
        id: 'app',
        kind: _ModuleKind.app,
        layer: _layerAt(segments, 1),
      );
    }
    if (segments.first == 'contexts' && segments.length >= 2) {
      return _ModuleLocation(
        id: 'contexts/${segments[1]}',
        kind: _ModuleKind.context,
        layer: _layerAt(segments, 2),
      );
    }
    if (segments.first == 'features' && segments.length >= 2) {
      return _ModuleLocation(
        id: 'features/${segments[1]}',
        kind: _ModuleKind.feature,
        layer: _layerAt(segments, 2),
      );
    }
    if (segments.first == 'shared' && segments.length >= 2) {
      final bool rootFile = segments[1].endsWith('.dart');
      return _ModuleLocation(
        id: rootFile ? 'shared' : 'shared/${segments[1]}',
        kind: _ModuleKind.shared,
        layer: null,
      );
    }
    return null;
  }

  bool isPublicEntryPoint(String relativePath) {
    return ArchitecturePublicSurfaceCatalog.contains(
      moduleId: id,
      relativePath: relativePath,
    );
  }

  static _ArchitecturalLayer? _layerAt(List<String> segments, int index) {
    if (segments.length <= index || segments[index].endsWith('.dart')) {
      return null;
    }
    return switch (segments[index]) {
      'domain' => _ArchitecturalLayer.domain,
      'application' => _ArchitecturalLayer.application,
      'infrastructure' => _ArchitecturalLayer.infrastructure,
      'presentation' => _ArchitecturalLayer.presentation,
      _ => null,
    };
  }
}

final class _PlatformIdentifierVisitor extends RecursiveAstVisitor<void> {
  const _PlatformIdentifierVisitor({required this.onPlatformIdentifier});

  final void Function(SimpleIdentifier identifier) onPlatformIdentifier;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_platformIdentifierNames.contains(node.name)) {
      onPlatformIdentifier(node);
    }
    super.visitSimpleIdentifier(node);
  }
}

final class _CliOptions {
  const _CliOptions({required this.sourceRoot, required this.packageName});

  final String sourceRoot;
  final String packageName;

  static _CliOptions parse(List<String> arguments) {
    String sourceRoot = '${Directory.current.path}${Platform.pathSeparator}lib';
    String packageName = 'clock_rhythm';

    for (int index = 0; index < arguments.length; index += 1) {
      final String argument = arguments[index];
      if (argument.startsWith('--source-root=')) {
        sourceRoot = argument.substring('--source-root='.length);
        continue;
      }
      if (argument == '--source-root' && index + 1 < arguments.length) {
        index += 1;
        sourceRoot = arguments[index];
        continue;
      }
      if (argument.startsWith('--package-name=')) {
        packageName = argument.substring('--package-name='.length);
        continue;
      }
      if (argument == '--package-name' && index + 1 < arguments.length) {
        index += 1;
        packageName = arguments[index];
        continue;
      }
      throw FormatException('Unknown or incomplete option: $argument');
    }

    return _CliOptions(sourceRoot: sourceRoot, packageName: packageName);
  }
}

void main(List<String> arguments) {
  try {
    final _CliOptions options = _CliOptions.parse(arguments);
    final ArchitectureScanResult result = ArchitectureScanner(
      sourceRoot: Directory(options.sourceRoot),
      packageName: options.packageName,
    ).scan();

    if (result.hasViolations) {
      stderr.writeln(
        'Architecture check failed with '
        '${result.violations.length} violation(s):',
      );
      for (final ArchitectureViolation violation in result.violations) {
        stderr.writeln(violation);
      }
      exitCode = 1;
      return;
    }

    stdout.writeln(
      'Architecture check passed (${result.scannedFileCount} Dart files).',
    );
  } on FileSystemException catch (error) {
    stderr.writeln(error.message);
    exitCode = 66;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(
      'Usage: dart run tool/check_architecture.dart '
      '[--source-root <path>] [--package-name <name>]',
    );
    exitCode = 64;
  }
}

const String _rhythmModuleId = 'contexts/rhythm';
const String _preferencesModuleId = 'contexts/preferences';
const String _todoModuleId = 'contexts/todo';
const String _dataTransferModuleId = 'features/data_transfer';
const String _sharedI18nModuleId = 'shared/i18n';
const String _sharedTimeModuleId = 'shared/time';
const String _sharedUiModuleId = 'shared/ui';

const Set<_ArchitecturalLayer?> _domainOutwardLayers = <_ArchitecturalLayer?>{
  _ArchitecturalLayer.application,
  _ArchitecturalLayer.infrastructure,
  _ArchitecturalLayer.presentation,
};

const Set<_ArchitecturalLayer?> _applicationOutwardLayers =
    <_ArchitecturalLayer?>{
      _ArchitecturalLayer.infrastructure,
      _ArchitecturalLayer.presentation,
    };

const Set<String> _approvedInnerLayerDartLibraries = <String>{
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:core',
  'dart:math',
  'dart:typed_data',
};

const Set<String> _approvedInnerLayerPackages = <String>{'characters'};

const Set<String> _approvedViewModelPackages = <String>{
  'flutter',
  'flutter_localizations',
  'flutter_riverpod',
  'go_router',
  'intl',
  'riverpod',
};

const Set<String> _platformPackages = <String>{
  'audioplayers',
  'drift_flutter',
  'file_picker',
  'flutter_local_notifications',
  'path_provider',
  'shared_preferences',
  'tray_manager',
  'window_manager',
};

const Set<String> _platformDartLibraries = <String>{
  'dart:ffi',
  'dart:html',
  'dart:io',
  'dart:js',
  'dart:js_interop',
  'dart:ui',
};

const Set<String> _platformIdentifierNames = <String>{
  'Platform',
  'TargetPlatform',
  'defaultTargetPlatform',
  'kIsWeb',
};

bool _isPreferencesRhythmModelEdge({
  required _ModuleLocation sourceModule,
  required _ModuleLocation targetModule,
  required String targetPath,
}) {
  return sourceModule.id == _preferencesModuleId &&
      targetModule.id == _rhythmModuleId &&
      targetModule.isPublicEntryPoint(targetPath) &&
      _baseName(targetPath) == 'public_model.dart';
}

_ArchitecturalLayer? _policyLayerFor({
  required _ModuleLocation? module,
  required String relativePath,
}) {
  final _ArchitecturalLayer? explicitLayer = module?.layer;
  if (explicitLayer != null) {
    return explicitLayer;
  }

  if (module?.id == _sharedTimeModuleId) {
    return _ArchitecturalLayer.domain;
  }

  if (module?.kind == _ModuleKind.app &&
      relativePath.startsWith('app/config/')) {
    return _ArchitecturalLayer.application;
  }

  final String baseName = _baseName(relativePath);
  if (module?.kind == _ModuleKind.context) {
    return switch (baseName) {
      'public_model.dart' => _ArchitecturalLayer.domain,
      'public.dart' => _ArchitecturalLayer.application,
      'public_presentation.dart' => _ArchitecturalLayer.presentation,
      _ => null,
    };
  }
  if (module?.id == _dataTransferModuleId && baseName == 'public.dart') {
    return _ArchitecturalLayer.application;
  }
  return null;
}

bool _isAllowedModuleLocation(_ArchitectureFile source) {
  final _ModuleLocation? module = source.module;
  if (module == null) {
    return source.relativePath == 'main.dart';
  }
  if (!ArchitecturePublicSurfaceCatalog.byModule.containsKey(module.id)) {
    return false;
  }
  if (module.isPublicEntryPoint(source.relativePath)) {
    return true;
  }

  return switch (module.kind) {
    _ModuleKind.app => _isAllowedAppLocation(source.relativePath),
    _ModuleKind.context => module.layer != null,
    _ModuleKind.feature =>
      module.id == _dataTransferModuleId &&
          const <_ArchitecturalLayer>{
            _ArchitecturalLayer.application,
            _ArchitecturalLayer.infrastructure,
            _ArchitecturalLayer.presentation,
          }.contains(module.layer),
    _ModuleKind.shared => true,
  };
}

bool _isAllowedAppLocation(String relativePath) {
  final List<String> segments = relativePath.split('/');
  if (segments.length == 2) {
    return const <String>{
      'clock_rhythm_app.dart',
      'platform_presentation_profile.dart',
    }.contains(segments.last);
  }
  if (segments.length < 3) {
    return false;
  }
  return const <String>{
    'application',
    'config',
    'composition',
    'infrastructure',
    'navigation',
    'presentation',
  }.contains(segments[1]);
}

bool _isAllowedSharedDependency({
  required String sourceModuleId,
  required String targetModuleId,
}) {
  return switch (sourceModuleId) {
    _sharedI18nModuleId => targetModuleId == _sharedTimeModuleId,
    _sharedUiModuleId =>
      targetModuleId == _sharedI18nModuleId ||
          targetModuleId == _sharedTimeModuleId,
    _ => false,
  };
}

bool _isApprovedInnerLayerExternalDependency(String rawUri) {
  final Uri? uri = Uri.tryParse(rawUri);
  if (uri == null) {
    return false;
  }
  if (uri.scheme == 'dart') {
    return _approvedInnerLayerDartLibraries.contains(rawUri);
  }
  return uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      _approvedInnerLayerPackages.contains(uri.pathSegments.first);
}

bool _isForbiddenPlatformDependency({
  required _ArchitectureFile source,
  required String rawUri,
  required bool isInternal,
}) {
  if (_platformDartLibraries.contains(rawUri)) {
    return true;
  }
  if (isInternal) {
    return false;
  }

  final String? packageName = _externalPackageName(rawUri);
  if (source.policyLayer == _ArchitecturalLayer.presentation &&
      _isViewModelLike(source)) {
    if (packageName != null) {
      return !_approvedViewModelPackages.contains(packageName);
    }
    final Uri? uri = Uri.tryParse(rawUri);
    return uri == null || (uri.scheme.isNotEmpty && uri.scheme != 'dart');
  }
  return packageName != null && _platformPackages.contains(packageName);
}

String? _externalPackageName(String rawUri) {
  final Uri? uri = Uri.tryParse(rawUri);
  if (uri == null || uri.scheme != 'package' || uri.pathSegments.isEmpty) {
    return null;
  }
  return uri.pathSegments.first;
}

bool _isPlatformRestrictedFile(_ArchitectureFile source) {
  final _ArchitecturalLayer? layer = source.policyLayer;
  return layer == _ArchitecturalLayer.domain ||
      layer == _ArchitecturalLayer.application ||
      (layer == _ArchitecturalLayer.presentation && _isViewModelLike(source));
}

bool _isViewModelLike(_ArchitectureFile source) {
  final String baseName = _baseName(source.relativePath).toLowerCase();
  if (baseName.contains('view_model') ||
      baseName.contains('viewmodel') ||
      baseName.endsWith('_notifier.dart') ||
      baseName.endsWith('_controller.dart')) {
    return true;
  }

  return source.unit.declarations.whereType<ClassDeclaration>().any(
    (ClassDeclaration declaration) =>
        _isViewModelClassName(declaration.namePart.beginToken.lexeme),
  );
}

bool _isViewModelClassName(String name) {
  return name.endsWith('ViewModel') ||
      name.endsWith('Notifier') ||
      name.endsWith('Controller');
}

bool _isDataTransferInfrastructureContract(String name) {
  final String lowerName = name.toLowerCase();
  return lowerName.endsWith('repository') || lowerName.endsWith('port');
}

String? _normalizeInternalSegments(Iterable<String> segments) {
  final List<String> normalizedSegments = <String>[];
  for (final String segment in segments) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (normalizedSegments.isEmpty) {
        return null;
      }
      normalizedSegments.removeLast();
      continue;
    }
    if (segment.contains('/') || segment.contains('\\')) {
      return null;
    }
    normalizedSegments.add(segment);
  }
  return normalizedSegments.isEmpty ? null : normalizedSegments.join('/');
}

String _normalizeFileSystemPath(String path) {
  return path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
}

String _baseName(String path) {
  return path.split('/').last;
}

int _compareViolations(
  ArchitectureViolation left,
  ArchitectureViolation right,
) {
  final int pathComparison = left.relativePath.compareTo(right.relativePath);
  if (pathComparison != 0) {
    return pathComparison;
  }
  final int lineComparison = left.line.compareTo(right.line);
  if (lineComparison != 0) {
    return lineComparison;
  }
  final int columnComparison = left.column.compareTo(right.column);
  if (columnComparison != 0) {
    return columnComparison;
  }
  return left.ruleId.compareTo(right.ruleId);
}
