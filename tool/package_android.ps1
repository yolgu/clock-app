[CmdletBinding()]
param(
    [ValidateSet('Beta', 'Production')]
    [string]$Flavor = 'Beta',
    [ValidateSet('Apk', 'AppBundle')]
    [string]$Artifact = 'Apk',
    [string]$OutputDirectory = 'artifacts\android',
    [string]$ManifestPath = 'artifacts\manifest.json',
    [switch]$SkipPreflight
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'source_snapshot.ps1')
[string]$sourceSnapshotSha256 = Get-ClockRhythmSourceSnapshotSha256 `
    -RepositoryRoot ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))

$release = if ($Flavor -eq 'Beta') {
    [ordered]@{
        FlavorId = 'beta'
        VersionName = '0.1.0'
        BuildNumber = 1
    }
} else {
    [ordered]@{
        FlavorId = 'production'
        VersionName = '1.0.0'
        BuildNumber = 1
    }
}

function Assert-ProductionSigningEnvironment {
    param()

    $requiredVariables = @(
        'CLOCK_RHYTHM_ANDROID_KEYSTORE',
        'CLOCK_RHYTHM_ANDROID_KEY_ALIAS',
        'CLOCK_RHYTHM_ANDROID_STORE_PASSWORD',
        'CLOCK_RHYTHM_ANDROID_KEY_PASSWORD'
    )
    $missingVariables = @(
        $requiredVariables | Where-Object {
            [string]::IsNullOrWhiteSpace(
                [Environment]::GetEnvironmentVariable($_)
            )
        }
    )
    if ($missingVariables.Count -gt 0) {
        throw "Production Android signing credentials are missing: $($missingVariables -join ', ')."
    }
    if (-not (Test-Path -LiteralPath $env:CLOCK_RHYTHM_ANDROID_KEYSTORE -PathType Leaf)) {
        throw 'Production Android keystore file does not exist.'
    }
    $keystorePath = [System.IO.Path]::GetFullPath(
        $env:CLOCK_RHYTHM_ANDROID_KEYSTORE
    )
    $repositoryRoot = [System.IO.Path]::GetFullPath((Get-Location))
    $repositoryRootPrefix =
        $repositoryRoot.TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ) + [System.IO.Path]::DirectorySeparatorChar
    if ($keystorePath.Equals(
            $repositoryRoot,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -or
        $keystorePath.StartsWith(
            $repositoryRootPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'Production Android keystore must be stored outside the repository.'
    }
}

function Resolve-FvmExecutable {
    [OutputType([string])]
    param()

    if (-not [string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_FVM) -and
        (Test-Path -LiteralPath $env:CLOCK_RHYTHM_FVM -PathType Leaf)) {
        return [System.IO.Path]::GetFullPath($env:CLOCK_RHYTHM_FVM)
    }
    $command = Get-Command 'fvm' -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw 'FVM is unavailable. Run the Android preflight or set CLOCK_RHYTHM_FVM.'
    }
    return $command.Source
}

function Remove-OwnedStagingDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$StagingRoot
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $resolvedRoot = [System.IO.Path]::GetFullPath($StagingRoot)
    if ((Split-Path -Parent $resolvedPath) -ne $resolvedRoot -or
        -not (Split-Path -Leaf $resolvedPath).StartsWith('android-')) {
        throw "Refusing unsafe Android staging cleanup: $resolvedPath"
    }
    if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
        Remove-Item -LiteralPath $resolvedPath -Recurse -Force
    }
}

if ($Flavor -eq 'Beta' -and $Artifact -eq 'AppBundle') {
    throw 'Beta distribution produces a signed APK; App Bundle is production-only.'
}
if ($Flavor -eq 'Production') {
    Assert-ProductionSigningEnvironment
}

if (-not $SkipPreflight) {
    & (Join-Path $PSScriptRoot 'preflight.ps1') -Platform Android
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
$fvmExecutable = Resolve-FvmExecutable

Write-Output 'Resolving the locked dependency graph and preparing Android platform files.'
& $fvmExecutable flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$androidDirectory = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) 'android'))
$gradleExecutable = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    Join-Path $androidDirectory 'gradlew.bat'
} else {
    Join-Path $androidDirectory 'gradlew'
}
$testTask = ":app:test$($Flavor)DebugUnitTest"
Push-Location $androidDirectory
try {
    & $gradleExecutable $testTask
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
& $fvmExecutable flutter build $flutterArtifact `
    --flavor $release.FlavorId `
    --release `
    --no-pub `
    --build-name $release.VersionName `
    --build-number $release.BuildNumber `
    "--dart-define=CLOCK_RHYTHM_FLAVOR=$($release.FlavorId)"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$builtArtifactPath = if ($Artifact -eq 'Apk') {
    "build\app\outputs\flutter-apk\app-$($release.FlavorId)-release.apk"
} else {
    "build\app\outputs\bundle\$($release.FlavorId)Release\app-$($release.FlavorId)-release.aab"
}
if (-not (Test-Path -LiteralPath $builtArtifactPath -PathType Leaf)) {
    throw "Expected Android build output is missing: $builtArtifactPath"
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $outputRoot | Out-Null
}
$stagingRoot = Join-Path $outputRoot '.staging'
if (-not (Test-Path -LiteralPath $stagingRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $stagingRoot | Out-Null
}
$stagingDirectory = Join-Path $stagingRoot `
    "android-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $stagingDirectory | Out-Null

$extension = if ($Artifact -eq 'Apk') { 'apk' } else { 'aab' }
$fileName = "clock-rhythm-$($release.FlavorId)-$($release.VersionName)+$($release.BuildNumber).$extension"
$stagedArtifact = Join-Path $stagingDirectory $fileName
$finalArtifact = Join-Path $outputRoot $fileName
$verifier = Join-Path $PSScriptRoot 'verify_artifact.ps1'
try {
    Copy-Item -LiteralPath $builtArtifactPath -Destination $stagedArtifact
    & $verifier -Platform Android -Type $Artifact -Flavor $Flavor `
        -ArtifactPath $stagedArtifact
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Copy-Item -LiteralPath $stagedArtifact -Destination $finalArtifact -Force
    & $verifier -Platform Android -Type $Artifact -Flavor $Flavor `
        -ArtifactPath $finalArtifact -ManifestPath $ManifestPath `
        -SourceSnapshotSha256 $sourceSnapshotSha256
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Remove-OwnedStagingDirectory -Path $stagingDirectory `
        -StagingRoot $stagingRoot
}

Write-Output "Android package: $finalArtifact"
