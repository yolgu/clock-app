[CmdletBinding()]
param(
    [ValidateSet('All', 'Windows', 'Android', 'Core')]
    [string]$Platform = 'All'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedFlutterVersion = '3.44.7'
[string]$fvmExecutable = ''
if (-not [string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_FVM) -and
    (Test-Path -LiteralPath $env:CLOCK_RHYTHM_FVM -PathType Leaf)) {
    $fvmExecutable = [System.IO.Path]::GetFullPath($env:CLOCK_RHYTHM_FVM)
}

if ([string]::IsNullOrWhiteSpace($fvmExecutable)) {
    $fvmCommand = Get-Command 'fvm' -ErrorAction SilentlyContinue
    $fvmExecutable = if ($null -ne $fvmCommand) { $fvmCommand.Source } else { '' }
}

if ([string]::IsNullOrWhiteSpace($fvmExecutable)) {
    foreach ($pathScope in @('User', 'Machine')) {
        $registeredPath = [Environment]::GetEnvironmentVariable('Path', $pathScope)
        foreach ($pathEntry in ($registeredPath -split ';')) {
            $directory = [Environment]::ExpandEnvironmentVariables($pathEntry.Trim().Trim('"'))
            if ([string]::IsNullOrWhiteSpace($directory)) {
                continue
            }

            $candidate = Join-Path $directory 'fvm.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $fvmExecutable = [System.IO.Path]::GetFullPath($candidate)
                break
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($fvmExecutable)) {
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($fvmExecutable)) {
    throw 'FVM is not available on the process, user, or machine PATH.'
}

$env:CLOCK_RHYTHM_FVM = $fvmExecutable

$fvmVersion = (& $fvmExecutable --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'FVM is installed but failed to start.'
}

$fvmConfiguration = Get-Content -Raw -LiteralPath '.fvmrc' | ConvertFrom-Json
if ($fvmConfiguration.flutter -ne $expectedFlutterVersion) {
    throw "Expected Flutter $expectedFlutterVersion in .fvmrc, found $($fvmConfiguration.flutter)."
}

$flutterVersion = (& $fvmExecutable flutter --version 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw 'FVM could not start the project Flutter SDK.'
}
if ($flutterVersion -notmatch "Flutter $([regex]::Escape($expectedFlutterVersion))") {
    throw "The active Flutter SDK is not $expectedFlutterVersion."
}

$doctor = (& $fvmExecutable flutter doctor -v 2>&1 | Out-String)
$doctorExitCode = $LASTEXITCODE
Write-Output $doctor.TrimEnd()

if ($doctorExitCode -ne 0) {
    throw 'Flutter doctor reports a blocking toolchain issue.'
}
if ($Platform -in @('All', 'Android')) {
    [string]$androidSdkPath = if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        $env:ANDROID_HOME
    } elseif (-not [string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) {
        $env:ANDROID_SDK_ROOT
    } elseif ($doctor -match 'Android SDK at\s+([^\r\n]+)') {
        $Matches[1].Trim()
    } else {
        ''
    }
    if ([string]::IsNullOrWhiteSpace($androidSdkPath)) {
        throw 'Android SDK path could not be resolved.'
    }
    $androidPlatform = Join-Path $androidSdkPath 'platforms/android-36'
    $androidBuildTools = Join-Path $androidSdkPath 'build-tools/36.0.0'
    if (-not (Test-Path -LiteralPath $androidPlatform -PathType Container) -or
        -not (Test-Path -LiteralPath $androidBuildTools -PathType Container) -or
        $doctor -match '\[X\]\s+Android toolchain') {
        throw 'Android platform 36 and Build Tools 36.0.0 must be installed.'
    }
}
if ($Platform -in @('All', 'Windows') -and
    ($doctor -notmatch 'Visual Studio - develop Windows apps' -or
     $doctor -match '\[X\]\s+Visual Studio - develop Windows apps')) {
    throw 'The Visual Studio Windows toolchain is not active.'
}

Write-Output "FVM $fvmVersion and Flutter $expectedFlutterVersion are ready for $Platform verification."
