[CmdletBinding()]
param(
    [ValidateSet('Beta', 'Production')]
    [string]$Flavor = 'Beta',
    [switch]$UnsignedStaging,
    [switch]$SkipPreflight
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SkipPreflight) {
    & (Join-Path $PSScriptRoot 'preflight.ps1') -Platform Windows
}

$fvmExecutable = $env:CLOCK_RHYTHM_FVM
if ([string]::IsNullOrWhiteSpace($fvmExecutable)) {
    throw 'Preflight did not resolve the FVM executable.'
}

if ($Flavor -eq 'Production' -and -not $UnsignedStaging) {
    if ([string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE) -or
        [string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD)) {
        throw 'Production Windows signing credentials are missing. Use -UnsignedStaging only for an explicitly unsigned inspection build.'
    }
    throw 'Production Windows signing is enabled by P20 packaging, not by the raw Flutter build gate.'
}

$flavorId = $Flavor.ToLowerInvariant()
$buildName = if ($Flavor -eq 'Beta') { '0.1.0' } else { '1.0.0' }
$buildNumber = '1'
Write-Output 'Resolving the locked dependency graph.'
& $fvmExecutable flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Write-Output "Building the $Flavor Windows release artifact."
$previousWindowsFlavor = [Environment]::GetEnvironmentVariable(
    'CLOCK_RHYTHM_WINDOWS_FLAVOR',
    [EnvironmentVariableTarget]::Process
)
$windowsBuildExitCode = 0
try {
    $env:CLOCK_RHYTHM_WINDOWS_FLAVOR = $flavorId
    & $fvmExecutable flutter build windows --release --no-pub `
        --build-name $buildName `
        --build-number $buildNumber `
        "--dart-define=CLOCK_RHYTHM_FLAVOR=$flavorId"
    $windowsBuildExitCode = $LASTEXITCODE
} finally {
    if ($null -eq $previousWindowsFlavor) {
        Remove-Item Env:CLOCK_RHYTHM_WINDOWS_FLAVOR -ErrorAction SilentlyContinue
    } else {
        $env:CLOCK_RHYTHM_WINDOWS_FLAVOR = $previousWindowsFlavor
    }
}
if ($windowsBuildExitCode -ne 0) {
    exit $windowsBuildExitCode
}

$nativeHarness = Join-Path $PSScriptRoot 'test_windows_lifecycle.ps1'
if (-not (Test-Path -LiteralPath $nativeHarness -PathType Leaf)) {
    throw "Required Windows native lifecycle harness is missing: $nativeHarness"
}
$releaseExecutable = Join-Path (Get-Location) `
    'build\windows\x64\runner\Release\clock_rhythm.exe'
& $nativeHarness -ExecutablePath $releaseExecutable -Flavor $flavorId `
    -SkipFlutterBuild
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($Flavor -eq 'Production') {
    Write-Warning 'This is an explicitly unsigned production staging build and is not releasable.'
}
Write-Output 'Windows bundle: build/windows/x64/runner/Release'
