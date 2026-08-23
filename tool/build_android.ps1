[CmdletBinding()]
param(
    [ValidateSet('Beta', 'Production')]
    [string]$Flavor = 'Beta',
    [ValidateSet('Apk', 'AppBundle')]
    [string]$Artifact = 'Apk',
    [switch]$UnsignedStaging,
    [switch]$SkipPreflight
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SkipPreflight) {
    & (Join-Path $PSScriptRoot 'preflight.ps1') -Platform Android
}

$fvmExecutable = $env:CLOCK_RHYTHM_FVM
if ([string]::IsNullOrWhiteSpace($fvmExecutable)) {
    throw 'Preflight did not resolve the FVM executable.'
}

if ($Flavor -eq 'Production' -and -not $UnsignedStaging) {
    $requiredVariables = @(
        'CLOCK_RHYTHM_ANDROID_KEYSTORE',
        'CLOCK_RHYTHM_ANDROID_KEY_ALIAS',
        'CLOCK_RHYTHM_ANDROID_STORE_PASSWORD',
        'CLOCK_RHYTHM_ANDROID_KEY_PASSWORD'
    )
    $missingVariables = @(
        $requiredVariables | Where-Object {
            [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_))
        }
    )
    if ($missingVariables.Count -gt 0) {
        throw "Production Android signing credentials are missing: $($missingVariables -join ', ')."
    }
    throw 'Production Android signing is enabled by P20 packaging, not by the raw Flutter build gate.'
}

$flavorId = $Flavor.ToLowerInvariant()
Write-Output 'Resolving the locked dependency graph and preparing platform files.'
& $fvmExecutable flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$isWindowsHost = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
$androidDirectory = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) 'android'))
$gradleExecutable = if ($isWindowsHost) {
    Join-Path $androidDirectory 'gradlew.bat'
} else {
    Join-Path $androidDirectory 'gradlew'
}
Push-Location $androidDirectory
try {
    & $gradleExecutable ':app:testDebugUnitTest'
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

$flutterArtifact = if ($Artifact -eq 'Apk') { 'apk' } else { 'appbundle' }
& (Join-Path $PSScriptRoot 'remove_stale_android_plugin_registrant.ps1')
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Write-Output "Building the $Flavor Android $Artifact release artifact."
& $fvmExecutable flutter build $flutterArtifact --release --no-pub `
    --flavor $flavorId `
    "--dart-define=CLOCK_RHYTHM_FLAVOR=$flavorId"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($Flavor -eq 'Production') {
    Write-Warning 'This is an explicitly unsigned production staging build and is not releasable.'
}
$artifactPath = if ($Artifact -eq 'Apk') {
    "build/app/outputs/flutter-apk/app-$flavorId-release.apk"
} else {
    "build/app/outputs/bundle/$($flavorId)Release/app-$flavorId-release.aab"
}
Write-Output "Android artifact: $artifactPath"
