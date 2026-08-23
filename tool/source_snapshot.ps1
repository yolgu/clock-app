Set-StrictMode -Version Latest

function Get-ClockRhythmSourceSnapshotSha256 {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot
    )

    [string]$resolvedRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
    [string]$rootPrefix = $resolvedRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
    [string[]]$sourceRoots = @(
        '.fvmrc',
        'analysis_options.yaml',
        'l10n.yaml',
        'pubspec.lock',
        'pubspec.yaml',
        'assets',
        'lib',
        'test',
        'integration_test',
        'tool',
        'android',
        'windows'
    )
    [System.Collections.Generic.Dictionary[string, string]]$filesByPath =
        [System.Collections.Generic.Dictionary[string, string]]::new(
            [System.StringComparer]::Ordinal
        )
    foreach ($relativeRoot in $sourceRoots) {
        [string]$absoluteRoot = Join-Path $resolvedRoot $relativeRoot
        if (Test-Path -LiteralPath $absoluteRoot -PathType Leaf) {
            [System.IO.FileInfo]$file = Get-Item -LiteralPath $absoluteRoot
            [string]$relativePath = $file.FullName.Substring(
                $rootPrefix.Length
            ).Replace('\', '/')
            $filesByPath.Add($relativePath, $file.FullName)
            continue
        }
        if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
            throw "Source snapshot input is missing: $relativeRoot"
        }
        foreach ($file in Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File -Force) {
            [string]$relativePath = $file.FullName.Substring(
                $rootPrefix.Length
            ).Replace('\', '/')
            if ($relativePath -eq 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java') {
                continue
            }
            if ($relativePath -match '(^|/)(?:build|\.dart_tool|\.gradle|\.kotlin|\.cxx|ephemeral|\.plugin_symlinks|node_modules)(/|$)') {
                continue
            }
            if ($relativePath -match '(?i)(?:^|/)(?:local\.properties|key\.properties)$' -or
                $relativePath -match '(?i)\.(?:jks|keystore|p12|pfx)$') {
                continue
            }
            $filesByPath.Add($relativePath, $file.FullName)
        }
    }

    [System.Collections.Generic.List[string]]$sortedPaths =
        [System.Collections.Generic.List[string]]::new()
    foreach ($relativePath in $filesByPath.Keys) {
        $sortedPaths.Add($relativePath)
    }
    $sortedPaths.Sort([System.StringComparer]::Ordinal)
    [System.Text.StringBuilder]$manifest = [System.Text.StringBuilder]::new()
    foreach ($relativePath in $sortedPaths) {
        [string]$fileHash = (
            Get-FileHash -LiteralPath $filesByPath[$relativePath] `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        [void]$manifest.Append($relativePath)
        [void]$manifest.Append("`t")
        [void]$manifest.Append($fileHash)
        [void]$manifest.Append("`n")
    }

    [byte[]]$bytes = [System.Text.Encoding]::UTF8.GetBytes(
        $manifest.ToString()
    )
    [System.Security.Cryptography.SHA256]$sha =
        [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString(
            $sha.ComputeHash($bytes)
        )).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}
