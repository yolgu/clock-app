[CmdletBinding()]
param(
    [ValidateSet('All', 'Windows', 'Android', 'Core')]
    [string]$Platform = 'All'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'preflight.ps1') -Platform $Platform

$fvmExecutable = $env:CLOCK_RHYTHM_FVM
if ([string]::IsNullOrWhiteSpace($fvmExecutable)) {
    throw 'Preflight did not resolve the FVM executable.'
}

Write-Output 'Checking documentation links and repository paths.'
& (Join-Path $PSScriptRoot 'check_docs.ps1')
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& (Join-Path $PSScriptRoot 'check_generated.ps1') -Platform $Platform -SkipPreflight
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output 'Checking Dart formatting.'
& $fvmExecutable dart format --output=none --set-exit-if-changed lib test integration_test tool
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output 'Checking architectural boundaries.'
& $fvmExecutable dart run tool/check_architecture.dart
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output 'Running static analysis.'
& $fvmExecutable flutter analyze
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output 'Running the complete Dart and Flutter test suite.'
& $fvmExecutable flutter test
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output 'Clock Rhythm verification completed.'
