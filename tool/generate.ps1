[CmdletBinding()]
param(
    [ValidateSet('All', 'Windows', 'Android', 'Core')]
    [string]$Platform = 'Core',
    [switch]$SkipPreflight,
    [switch]$SkipDependencyResolution
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SkipPreflight) {
    & (Join-Path $PSScriptRoot 'preflight.ps1') -Platform $Platform
}

$fvmExecutable = $env:CLOCK_RHYTHM_FVM
if ([string]::IsNullOrWhiteSpace($fvmExecutable)) {
    throw 'Preflight did not resolve the FVM executable.'
}

if (-not $SkipDependencyResolution) {
    Write-Output 'Resolving the locked dependency graph.'
    & $fvmExecutable flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Output 'Generating Flutter localizations.'
& $fvmExecutable flutter gen-l10n
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output 'Generating Drift and other registered build_runner outputs.'
& $fvmExecutable dart run build_runner build
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
