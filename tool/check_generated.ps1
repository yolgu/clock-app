[CmdletBinding()]
param(
    [ValidateSet('All', 'Windows', 'Android', 'Core')]
    [string]$Platform = 'Core',
    [switch]$SkipPreflight
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SkipPreflight) {
    & (Join-Path $PSScriptRoot 'preflight.ps1') -Platform $Platform
}

function Get-GeneratedFileState {
    [CmdletBinding()]
    param()

    $state = @{}
    $root = [System.IO.Path]::GetFullPath((Get-Location).Path)
    $generatedFiles = Get-ChildItem -LiteralPath (Join-Path $root 'lib') -Recurse -File |
        Where-Object {
            $_.Name.EndsWith('.g.dart', [System.StringComparison]::Ordinal) -or
            $_.FullName.Replace('\', '/').Contains('/lib/l10n/generated/')
        }

    foreach ($file in $generatedFiles) {
        $relativePath = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
        $state[$relativePath] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }

    return $state
}

$before = Get-GeneratedFileState
Write-Output 'Resolving the locked dependency graph after capturing generated baselines.'
& $env:CLOCK_RHYTHM_FVM flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
& (Join-Path $PSScriptRoot 'generate.ps1') -Platform $Platform -SkipPreflight -SkipDependencyResolution
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
$after = Get-GeneratedFileState

$changedPaths = @(
    @($before.Keys) + @($after.Keys) |
        Sort-Object -Unique |
        Where-Object {
            -not $before.ContainsKey($_) -or
            -not $after.ContainsKey($_) -or
            $before[$_] -ne $after[$_]
        }
)

if ($changedPaths.Count -gt 0) {
    Write-Error "Generated output was stale:`n$($changedPaths -join [Environment]::NewLine)"
}

Write-Output "Generated output is current ($($after.Count) files)."
