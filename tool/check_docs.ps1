[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string]$repositoryRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..')
)
[string]$repositoryRootPrefix =
    $repositoryRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
[string[]]$documentationPaths = @(
    'README.md',
    'docs/setup/windows-android-toolchain.md',
    'docs/migration/neutralino-to-flutter.md',
    'docs/release/release-process.md',
    'docs/verification/platform-checklist.md',
    'docs/privacy-and-data.md',
    'docs/troubleshooting.md'
)
[string[]]$linkScanPaths = @(
    Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File -Filter '*.md' |
        Where-Object {
            $_.FullName -notmatch '[\\/](?:node_modules|build|\.dart_tool|\.fvm)[\\/]'
        } |
        ForEach-Object {
            $_.FullName.Substring($repositoryRootPrefix.Length)
        }
)
[string[]]$requiredRepositoryPaths = @(
    '.fvmrc',
    'pubspec.lock',
    'ASSET_NOTICE.md',
    'THIRD_PARTY_NOTICES.md',
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
    'tool/check_release_evidence.ps1',
    'tool/source_snapshot.ps1',
    'tool/signing.env.example.ps1',
    'tool/test_windows_lifecycle.ps1',
    'tool/test_android_lifecycle.ps1',
    'artifacts/manifest.example.json',
    'docs/testing/android-lifecycle-checklist.md',
    'docs/testing/android-emulator-e2e.md',
    'docs/testing/accessibility-manual-checklist.md',
    'docs/verification/ci-gates.md',
    'docs/verification/legacy-behavior-matrix.md',
    'android/app/src/main/AndroidManifest.xml',
    'android/app/build.gradle.kts',
    'windows/runner/CMakeLists.txt'
)
[System.Collections.Generic.List[string]]$failures =
    [System.Collections.Generic.List[string]]::new()
[regex]$markdownLinkPattern = [regex]::new(
    '(?<!!)(?:\[[^\]]*\])\((?<target><[^>]+>|[^)\s]+)(?:\s+"[^"]*")?\)',
    [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
)
[regex]$repositoryPathPattern = [regex]::new(
    '(?<![:/A-Za-z0-9_.-])(?<path>(?:tool|docs|android|windows|lib|test|assets|\.github)/[A-Za-z0-9_./-]+)',
    [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
)
[regex]$machinePathPattern = [regex]::new(
    '(?i)(?:[A-Z]:\\Users\\[^\\\s]+|/home/[^/\s]+|/Users/[^/\s]+)',
    [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
)

function Resolve-RepositoryPath {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $Path))
}

function Test-RepositoryTarget {
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    [string]$withoutFragment = ($Target -split '[#?]', 2)[0]
    if ([string]::IsNullOrWhiteSpace($withoutFragment)) {
        return
    }
    [string]$decodedTarget = [System.Uri]::UnescapeDataString(
        $withoutFragment.Trim('<', '>')
    )
    if ($decodedTarget -match '^[A-Za-z][A-Za-z0-9+.-]*:' -or
        $decodedTarget.StartsWith('//')) {
        return
    }
    if ([System.IO.Path]::IsPathRooted($decodedTarget)) {
        $failures.Add("$SourcePath uses an absolute local link: $Target")
        return
    }

    [string]$sourceDirectory = Split-Path -Parent (
        Resolve-RepositoryPath -Path $SourcePath
    )
    [string]$resolvedTarget = [System.IO.Path]::GetFullPath(
        (Join-Path $sourceDirectory $decodedTarget)
    )
    if (-not $resolvedTarget.StartsWith(
        $repositoryRootPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        $failures.Add("$SourcePath links outside the repository: $Target")
        return
    }
    if (-not (Test-Path -LiteralPath $resolvedTarget)) {
        $failures.Add("$SourcePath has a missing local link: $Target")
    }
}

foreach ($requiredPath in $requiredRepositoryPaths) {
    [string]$resolvedRequiredPath = Resolve-RepositoryPath -Path $requiredPath
    if (-not (Test-Path -LiteralPath $resolvedRequiredPath)) {
        $failures.Add("Required documented repository path is missing: $requiredPath")
    }
}

foreach ($linkScanPath in $linkScanPaths) {
    [string]$resolvedLinkScanDocument = Resolve-RepositoryPath -Path $linkScanPath
    [string]$linkScanContent = Get-Content -Raw -LiteralPath $resolvedLinkScanDocument
    foreach ($linkMatch in $markdownLinkPattern.Matches($linkScanContent)) {
        Test-RepositoryTarget `
            -SourcePath $linkScanPath `
            -Target $linkMatch.Groups['target'].Value
    }
}

foreach ($documentationPath in $documentationPaths) {
    [string]$resolvedDocument = Resolve-RepositoryPath -Path $documentationPath
    if (-not (Test-Path -LiteralPath $resolvedDocument -PathType Leaf)) {
        $failures.Add("Required documentation file is missing: $documentationPath")
        continue
    }

    [string]$content = Get-Content -Raw -LiteralPath $resolvedDocument
    if ($machinePathPattern.IsMatch($content)) {
        $failures.Add("$documentationPath contains a machine-specific user path")
    }
    if ($content -match '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----') {
        $failures.Add("$documentationPath contains private-key material")
    }

    foreach ($pathMatch in
        $repositoryPathPattern.Matches($content)) {
        [string]$referencedPath = $pathMatch.Groups['path'].Value.TrimEnd(
            '.',
            ',',
            ':',
            ';'
        )
        [string]$resolvedReference = Resolve-RepositoryPath -Path $referencedPath
        if (-not (Test-Path -LiteralPath $resolvedReference)) {
            $failures.Add(
                "$documentationPath references a missing repository path: $referencedPath"
            )
        }
    }
}

if ($failures.Count -gt 0) {
    throw "Documentation verification failed:`n$($failures -join [Environment]::NewLine)"
}

Write-Output (
    "Documentation links and repository paths are valid " +
    "($($linkScanPaths.Count) Markdown files; " +
    "$($documentationPaths.Count) P21 contract documents)."
)
