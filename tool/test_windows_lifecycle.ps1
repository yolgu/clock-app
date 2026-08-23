[CmdletBinding()]
param(
  [string]$ExecutablePath = '',
  [switch]$SkipFlutterBuild,
  [switch]$VerifyFlavorIsolation,
  [switch]$VerifyReadinessRegression
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspacePath = [System.IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot '..')
)
$buildPath = Join-Path $workspacePath 'build\windows\x64'
$defaultExecutablePath = Join-Path $buildPath 'runner\Debug\clock_rhythm.exe'
$resolvedExecutablePath = if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
  $defaultExecutablePath
} else {
  [System.IO.Path]::GetFullPath($ExecutablePath)
}
$nativeTestPath = Join-Path $buildPath `
  'runner\Debug\clock_rhythm_windows_native_tests.exe'
$runRegistryPath = `
  'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'
$registrationName = `
  "Clock Rhythm Lifecycle Test $([guid]::NewGuid().ToString('N'))"
$siblingRegistrationName = "$registrationName.Sibling"
$ownedProcesses = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ClockRhythmLifecycleNative
{
    private const uint WmClose = 0x0010;
    private const uint RequestApplicationExit = 0x8031;

    private delegate bool EnumWindowsCallback(IntPtr window, IntPtr parameter);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(
        EnumWindowsCallback callback,
        IntPtr parameter);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(
        IntPtr window,
        out uint processId);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr window);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr GetProp(IntPtr window, string name);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool PostMessage(
        IntPtr window,
        uint message,
        IntPtr wParam,
        IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    public static IntPtr FindWindow(int processId)
    {
        IntPtr found = IntPtr.Zero;
        EnumWindows(
            delegate(IntPtr window, IntPtr parameter)
            {
                uint ownerProcessId;
                GetWindowThreadProcessId(window, out ownerProcessId);
                if (ownerProcessId == (uint)processId)
                {
                    found = window;
                    return false;
                }
                return true;
            },
            IntPtr.Zero);
        return found;
    }

    public static bool IsVisible(IntPtr window)
    {
        return window != IntPtr.Zero && IsWindowVisible(window);
    }

    public static bool IsReady(IntPtr window)
    {
        return window != IntPtr.Zero &&
            GetProp(window, "ClockRhythm.Lifecycle.Ready") != IntPtr.Zero;
    }

    public static bool HideThroughClose(IntPtr window)
    {
        return window != IntPtr.Zero &&
            PostMessage(window, WmClose, IntPtr.Zero, IntPtr.Zero);
    }

    public static bool ExitThroughLifecycleMessage(IntPtr window)
    {
        return window != IntPtr.Zero &&
            PostMessage(
                window,
                RequestApplicationExit,
                IntPtr.Zero,
                IntPtr.Zero);
    }
}
'@

function Invoke-CheckedCommand {
  [OutputType([void])]
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code $LASTEXITCODE`: $FilePath"
  }
}

function Wait-Condition {
  [OutputType([void])]
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Condition,
    [Parameter(Mandatory = $true)]
    [int]$TimeoutMilliseconds,
    [Parameter(Mandatory = $true)]
    [string]$Description
  )

  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
    if ([bool](& $Condition)) {
      return
    }
    Start-Sleep -Milliseconds 50
  }
  throw "Timed out waiting for $Description."
}

function Start-OwnedProcess {
  [OutputType([System.Diagnostics.Process])]
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [string[]]$Arguments = @()
  )

  $process = if ($Arguments.Count -eq 0) {
    Start-Process -FilePath $FilePath -PassThru
  } else {
    Start-Process -FilePath $FilePath -ArgumentList $Arguments -PassThru
  }
  $ownedProcesses.Add($process)
  return $process
}

function Get-ExactRunRegistration {
  [OutputType([object])]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  try {
    $key = Get-Item -LiteralPath $runRegistryPath
  } catch [System.Management.Automation.ItemNotFoundException] {
    return $null
  }
  return $key.GetValue(
    $Name,
    $null,
    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
  )
}

function Assert-ExitedSuccessfully {
  [OutputType([void])]
  param(
    [Parameter(Mandatory = $true)]
    [System.Diagnostics.Process]$Process,
    [Parameter(Mandatory = $true)]
    [string]$Description
  )

  if (-not $Process.WaitForExit(5000)) {
    throw "$Description did not exit."
  }
  if ($Process.ExitCode -ne 0) {
    throw "$Description exited with code $($Process.ExitCode)."
  }
}

function Assert-StablyHidden {
  [OutputType([void])]
  param(
    [Parameter(Mandatory = $true)]
    [System.Diagnostics.Process]$Process,
    [Parameter(Mandatory = $true)]
    [IntPtr]$Window,
    [int]$ReadinessTimeoutMilliseconds = 10000,
    [int]$StabilityMilliseconds = 1000
  )

  $readinessStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  while ($readinessStopwatch.ElapsedMilliseconds -lt `
      $ReadinessTimeoutMilliseconds) {
    if ($Process.HasExited) {
      throw 'Hidden primary exited before Flutter first-frame readiness.'
    }
    if ([ClockRhythmLifecycleNative]::IsVisible($Window)) {
      throw 'Hidden primary became visible before Flutter first-frame readiness.'
    }
    if ([ClockRhythmLifecycleNative]::IsReady($Window)) {
      break
    }
    Start-Sleep -Milliseconds 50
  }
  if (-not [ClockRhythmLifecycleNative]::IsReady($Window)) {
    throw 'Timed out waiting for hidden Flutter first-frame readiness.'
  }

  $stabilityStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  while ($stabilityStopwatch.ElapsedMilliseconds -lt $StabilityMilliseconds) {
    if ($Process.HasExited) {
      throw 'Hidden primary exited during the invisibility stability interval.'
    }
    if ([ClockRhythmLifecycleNative]::IsVisible($Window)) {
      throw 'Hidden primary became visible after Flutter first-frame readiness.'
    }
    Start-Sleep -Milliseconds 50
  }
}

function Assert-CMakeFlavorCache {
  [OutputType([void])]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('beta', 'production')]
    [string]$Flavor
  )

  $expectedIdentity = if ($Flavor -eq 'beta') {
    'dev.wndls.clockrhythm.beta'
  } else {
    'dev.wndls.clockrhythm'
  }
  $expectedRegistration = if ($Flavor -eq 'beta') {
    'Clock Rhythm Beta'
  } else {
    'Clock Rhythm'
  }
  $expectedTaskId = if ($Flavor -eq 'beta') {
    'ClockRhythmBetaStartup'
  } else {
    'ClockRhythmStartup'
  }
  $cache = Get-Content -LiteralPath (Join-Path $buildPath 'CMakeCache.txt')
  $expectedLines = @(
    "CLOCK_RHYTHM_WINDOWS_FLAVOR:STRING=$Flavor",
    "CLOCK_RHYTHM_WINDOWS_IDENTITY:INTERNAL=$expectedIdentity",
    "CLOCK_RHYTHM_AUTOSTART_REGISTRATION_NAME:INTERNAL=$expectedRegistration",
    "CLOCK_RHYTHM_STARTUP_TASK_ID:INTERNAL=$expectedTaskId"
  )
  foreach ($expectedLine in $expectedLines) {
    if ($cache -notcontains $expectedLine) {
      throw "CMake flavor cache mismatch: $expectedLine"
    }
  }
}

function Stop-PrimaryThroughLifecycleMessage {
  [OutputType([void])]
  param(
    [Parameter(Mandatory = $true)]
    [System.Diagnostics.Process]$Process,
    [Parameter(Mandatory = $true)]
    [IntPtr]$Window
  )

  if (-not [ClockRhythmLifecycleNative]::ExitThroughLifecycleMessage($Window)) {
    throw 'Could not post the lifecycle exit message.'
  }
  if (-not $Process.WaitForExit(5000)) {
    throw 'The primary process did not exit after the lifecycle request.'
  }
}

function Invoke-FlavorIsolationMatrix {
  [OutputType([void])]
  param()

  $matrixPath = [System.IO.Path]::GetFullPath(
    (Join-Path $buildPath `
      "p14_flavor_matrix_$([guid]::NewGuid().ToString('N'))")
  )
  $safeBuildPrefix = [System.IO.Path]::GetFullPath($buildPath) + `
    [System.IO.Path]::DirectorySeparatorChar
  if (-not $matrixPath.StartsWith(
      $safeBuildPrefix,
      [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw 'Refusing an unsafe flavor-matrix directory.'
  }

  $flavorProcesses = `
    [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
  $previousFlavor = [Environment]::GetEnvironmentVariable(
    'CLOCK_RHYTHM_WINDOWS_FLAVOR',
    'Process'
  )

  try {
    New-Item -ItemType Directory -Path $matrixPath | Out-Null
    $env:CLOCK_RHYTHM_WINDOWS_FLAVOR = 'beta'
    Invoke-CheckedCommand -FilePath 'fvm' -Arguments @(
      'flutter', 'build', 'windows', '--debug'
    )
    Assert-CMakeFlavorCache -Flavor beta
    $betaDirectory = Join-Path $matrixPath 'beta'
    Copy-Item -LiteralPath (Join-Path $buildPath 'runner\Debug') `
      -Destination $betaDirectory -Recurse

    Remove-Item Env:\CLOCK_RHYTHM_WINDOWS_FLAVOR -ErrorAction SilentlyContinue
    Invoke-CheckedCommand -FilePath 'fvm' -Arguments @(
      'flutter', 'build', 'windows', '--debug'
    )
    Assert-CMakeFlavorCache -Flavor production
    $productionDirectory = Join-Path $matrixPath 'production'
    Copy-Item -LiteralPath (Join-Path $buildPath 'runner\Debug') `
      -Destination $productionDirectory -Recurse

    $betaExecutable = Join-Path $betaDirectory 'clock_rhythm.exe'
    $productionExecutable = Join-Path $productionDirectory 'clock_rhythm.exe'
    $betaProcess = Start-Process -FilePath $betaExecutable `
      -ArgumentList @('--hidden') -PassThru
    $flavorProcesses.Add($betaProcess)
    $productionProcess = Start-Process -FilePath $productionExecutable `
      -ArgumentList @('--hidden') -PassThru
    $flavorProcesses.Add($productionProcess)

    Wait-Condition -TimeoutMilliseconds 10000 `
      -Description 'the beta flavor primary window handle' -Condition {
        $script:betaFlavorWindow = `
          [ClockRhythmLifecycleNative]::FindWindow($betaProcess.Id)
        -not $betaProcess.HasExited -and
        $script:betaFlavorWindow -ne [IntPtr]::Zero
      }
    Assert-StablyHidden -Process $betaProcess -Window $script:betaFlavorWindow
    Wait-Condition -TimeoutMilliseconds 10000 `
      -Description 'the production flavor primary window handle' -Condition {
        $script:productionFlavorWindow = `
          [ClockRhythmLifecycleNative]::FindWindow($productionProcess.Id)
        -not $productionProcess.HasExited -and
        $script:productionFlavorWindow -ne [IntPtr]::Zero
      }
    Assert-StablyHidden -Process $productionProcess `
      -Window $script:productionFlavorWindow

    $duplicateBeta = Start-Process -FilePath $betaExecutable `
      -ArgumentList @('--hidden') -PassThru
    $flavorProcesses.Add($duplicateBeta)
    Assert-ExitedSuccessfully -Process $duplicateBeta `
      -Description 'the duplicate beta hidden launch'

    Stop-PrimaryThroughLifecycleMessage -Process $betaProcess `
      -Window $script:betaFlavorWindow
    Stop-PrimaryThroughLifecycleMessage -Process $productionProcess `
      -Window $script:productionFlavorWindow
    Write-Output `
      'Beta and production primaries coexisted; beta duplicate exited silently.'
  } finally {
    foreach ($process in $flavorProcesses) {
      if (-not $process.HasExited) {
        $window = [ClockRhythmLifecycleNative]::FindWindow($process.Id)
        if ($window -ne [IntPtr]::Zero) {
          [void][ClockRhythmLifecycleNative]::ExitThroughLifecycleMessage(
            $window
          )
          [void]$process.WaitForExit(2000)
        }
        if (-not $process.HasExited) {
          Stop-Process -Id $process.Id -Force
        }
      }
      $process.Dispose()
    }
    [Environment]::SetEnvironmentVariable(
      'CLOCK_RHYTHM_WINDOWS_FLAVOR',
      $previousFlavor,
      'Process'
    )
    if (Test-Path -LiteralPath $matrixPath) {
      $verifiedMatrixPath = [System.IO.Path]::GetFullPath($matrixPath)
      if (-not $verifiedMatrixPath.StartsWith(
          $safeBuildPrefix,
          [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'Refusing unsafe flavor-matrix cleanup.'
      }
      Remove-Item -LiteralPath $verifiedMatrixPath -Recurse -Force
    }
  }
}

function Invoke-ReadinessRegressionProbe {
  [OutputType([void])]
  param()

  $regressionPath = [System.IO.Path]::GetFullPath(
    (Join-Path $buildPath `
      "p14_readiness_regression_$([guid]::NewGuid().ToString('N'))")
  )
  $safeBuildPrefix = [System.IO.Path]::GetFullPath($buildPath) + `
    [System.IO.Path]::DirectorySeparatorChar
  if (-not $regressionPath.StartsWith(
      $safeBuildPrefix,
      [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw 'Refusing an unsafe readiness-regression directory.'
  }
  $regressionProcess = $null
  $previousInjection = [Environment]::GetEnvironmentVariable(
    'CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START',
    'Process'
  )
  $previousFlavor = [Environment]::GetEnvironmentVariable(
    'CLOCK_RHYTHM_WINDOWS_FLAVOR',
    'Process'
  )

  try {
    New-Item -ItemType Directory -Path $regressionPath | Out-Null
    $env:CLOCK_RHYTHM_WINDOWS_FLAVOR = 'production'
    $env:CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START = '1'
    Invoke-CheckedCommand -FilePath 'fvm' -Arguments @(
      'flutter', 'build', 'windows', '--debug'
    )
    $regressionDirectory = Join-Path $regressionPath 'injected'
    Copy-Item -LiteralPath (Join-Path $buildPath 'runner\Debug') `
      -Destination $regressionDirectory -Recurse
    $regressionExecutable = Join-Path $regressionDirectory 'clock_rhythm.exe'
    $regressionProcess = Start-Process -FilePath $regressionExecutable `
      -ArgumentList @('--hidden') -PassThru
    $ownedProcesses.Add($regressionProcess)
    Wait-Condition -TimeoutMilliseconds 10000 `
      -Description 'the injected hidden window handle' -Condition {
        $script:regressionWindow = `
          [ClockRhythmLifecycleNative]::FindWindow($regressionProcess.Id)
        $script:regressionWindow -ne [IntPtr]::Zero
      }
    $injectionDetected = $false
    try {
      Assert-StablyHidden -Process $regressionProcess `
        -Window $script:regressionWindow
    } catch {
      if ($_.Exception.Message -like 'Hidden primary became visible*') {
        $injectionDetected = $true
      } else {
        throw
      }
    }
    if (-not $injectionDetected) {
      throw 'The readiness harness false-passed the visible-start injection.'
    }
    Stop-PrimaryThroughLifecycleMessage -Process $regressionProcess `
      -Window $script:regressionWindow
    Write-Output 'Visible hidden-start regression was detected as expected.'
  } finally {
    if ($null -ne $regressionProcess -and
        -not $regressionProcess.HasExited) {
      $regressionWindow = [ClockRhythmLifecycleNative]::FindWindow(
        $regressionProcess.Id
      )
      if ($regressionWindow -ne [IntPtr]::Zero) {
        [void][ClockRhythmLifecycleNative]::ExitThroughLifecycleMessage(
          $regressionWindow
        )
        [void]$regressionProcess.WaitForExit(2000)
      }
      if (-not $regressionProcess.HasExited) {
        Stop-Process -Id $regressionProcess.Id -Force
      }
    }
    if (Test-Path -LiteralPath $regressionPath) {
      $verifiedRegressionPath = [System.IO.Path]::GetFullPath($regressionPath)
      if (-not $verifiedRegressionPath.StartsWith(
          $safeBuildPrefix,
          [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'Refusing unsafe readiness-regression cleanup.'
      }
      Remove-Item -LiteralPath $verifiedRegressionPath -Recurse -Force
    }
    try {
      [Environment]::SetEnvironmentVariable(
        'CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START',
        $null,
        'Process'
      )
      $env:CLOCK_RHYTHM_WINDOWS_FLAVOR = 'production'
      Invoke-CheckedCommand -FilePath 'fvm' -Arguments @(
        'flutter', 'build', 'windows', '--debug'
      )
    } finally {
      [Environment]::SetEnvironmentVariable(
        'CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START',
        $previousInjection,
        'Process'
      )
      [Environment]::SetEnvironmentVariable(
        'CLOCK_RHYTHM_WINDOWS_FLAVOR',
        $previousFlavor,
        'Process'
      )
    }
  }
}

Push-Location $workspacePath
try {
  if (-not $SkipFlutterBuild) {
    Invoke-CheckedCommand -FilePath 'fvm' -Arguments @(
      'flutter', 'build', 'windows', '--debug'
    )
  }
  $cmakeCachePath = Join-Path $buildPath 'CMakeCache.txt'
  if (-not (Test-Path -LiteralPath $cmakeCachePath -PathType Leaf)) {
    throw "CMake cache not found after Flutter build: $cmakeCachePath"
  }
  $cmakeCommandLine = Get-Content -LiteralPath $cmakeCachePath |
    Where-Object { $_ -like 'CMAKE_COMMAND:INTERNAL=*' } |
    Select-Object -First 1
  if ($null -eq $cmakeCommandLine) {
    throw 'The Flutter CMake cache does not declare CMAKE_COMMAND.'
  }
  $cmakePath = $cmakeCommandLine.Substring(
    'CMAKE_COMMAND:INTERNAL='.Length
  )
  if (-not (Test-Path -LiteralPath $cmakePath -PathType Leaf)) {
    throw "Flutter's configured CMake executable was not found: $cmakePath"
  }
  Invoke-CheckedCommand -FilePath $cmakePath -Arguments @(
    '--build', $buildPath,
    '--config', 'Debug',
    '--target', 'clock_rhythm_windows_native_tests'
  )

  if (-not (Test-Path -LiteralPath $resolvedExecutablePath -PathType Leaf)) {
    throw "Windows executable not found: $resolvedExecutablePath"
  }
  if (-not (Test-Path -LiteralPath $nativeTestPath -PathType Leaf)) {
    throw "Native lifecycle test executable not found: $nativeTestPath"
  }
  $trayIconPath = Join-Path (Split-Path $resolvedExecutablePath -Parent) `
    'data\flutter_assets\windows\runner\resources\app_icon.ico'
  if (-not (Test-Path -LiteralPath $trayIconPath -PathType Leaf)) {
    throw "Packaged Windows tray ICO not found: $trayIconPath"
  }
  $runnerProjectPath = Join-Path $buildPath 'runner\clock_rhythm.vcxproj'
  if (-not (Select-String -LiteralPath $runnerProjectPath `
      -SimpleMatch `
      '<WindowsTargetPlatformMinVersion>10.0.17763.0</WindowsTargetPlatformMinVersion>' `
      -Quiet)) {
    throw 'Windows 10.0.17763.0 minimum-version contract is missing.'
  }

  $existingTargetProcesses = @(Get-Process -Name 'clock_rhythm' `
      -ErrorAction SilentlyContinue | Where-Object {
        try {
          [System.IO.Path]::GetFullPath($_.Path) -eq $resolvedExecutablePath
        } catch {
          $false
        }
      })
  if ($existingTargetProcesses.Count -ne 0) {
    throw 'The target executable is already running; no process was changed.'
  }
  if ($null -ne (Get-ExactRunRegistration -Name $registrationName) -or
      $null -ne (Get-ExactRunRegistration -Name $siblingRegistrationName)) {
    throw 'The generated harness registration unexpectedly already exists.'
  }

  Invoke-CheckedCommand -FilePath $nativeTestPath -Arguments @(
    $registrationName
  )
  if ($null -ne (Get-ExactRunRegistration -Name $registrationName) -or
      $null -ne (Get-ExactRunRegistration -Name $siblingRegistrationName)) {
    throw 'The native autostart test registration was not cleaned up.'
  }

  $primary = Start-OwnedProcess -FilePath $resolvedExecutablePath
  Wait-Condition -TimeoutMilliseconds 10000 `
    -Description 'the first interactive window' -Condition {
      $script:interactiveWindow = `
        [ClockRhythmLifecycleNative]::FindWindow($primary.Id)
      [ClockRhythmLifecycleNative]::IsReady($script:interactiveWindow) -and
      [ClockRhythmLifecycleNative]::IsVisible($script:interactiveWindow)
    }

  $secondInteractive = Start-OwnedProcess -FilePath $resolvedExecutablePath
  Assert-ExitedSuccessfully -Process $secondInteractive `
    -Description 'the second interactive launch'
  Wait-Condition -TimeoutMilliseconds 5000 `
    -Description 'the first window to receive focus' -Condition {
      [ClockRhythmLifecycleNative]::GetForegroundWindow() -eq `
        $script:interactiveWindow
    }

  if (-not [ClockRhythmLifecycleNative]::HideThroughClose(
      $script:interactiveWindow)) {
    throw 'Could not post WM_CLOSE to the primary window.'
  }
  Wait-Condition -TimeoutMilliseconds 5000 `
    -Description 'close-to-hide without process exit' -Condition {
      -not $primary.HasExited -and
      -not [ClockRhythmLifecycleNative]::IsVisible($script:interactiveWindow)
    }

  $secondHidden = Start-OwnedProcess -FilePath $resolvedExecutablePath `
    -Arguments @('--hidden')
  Assert-ExitedSuccessfully -Process $secondHidden `
    -Description 'the second hidden launch'
  if ([ClockRhythmLifecycleNative]::IsVisible($script:interactiveWindow)) {
    throw 'The second hidden launch surfaced the existing window.'
  }

  $reopenLaunch = Start-OwnedProcess -FilePath $resolvedExecutablePath
  Assert-ExitedSuccessfully -Process $reopenLaunch `
    -Description 'the interactive reopen launch'
  Wait-Condition -TimeoutMilliseconds 5000 `
    -Description 'the hidden primary window to reopen' -Condition {
      [ClockRhythmLifecycleNative]::IsVisible($script:interactiveWindow)
    }
  Stop-PrimaryThroughLifecycleMessage -Process $primary `
    -Window $script:interactiveWindow

  $hiddenPrimary = Start-OwnedProcess -FilePath $resolvedExecutablePath `
    -Arguments @('--hidden')
  Wait-Condition -TimeoutMilliseconds 10000 `
    -Description 'the first hidden window handle' -Condition {
      $script:hiddenWindow = `
        [ClockRhythmLifecycleNative]::FindWindow($hiddenPrimary.Id)
      $script:hiddenWindow -ne [IntPtr]::Zero
    }
  Assert-StablyHidden -Process $hiddenPrimary -Window $script:hiddenWindow
  $hiddenDuplicate = Start-OwnedProcess -FilePath $resolvedExecutablePath `
    -Arguments @('--hidden')
  Assert-ExitedSuccessfully -Process $hiddenDuplicate `
    -Description 'the duplicate hidden launch'
  if ([ClockRhythmLifecycleNative]::IsVisible($script:hiddenWindow)) {
    throw 'A duplicate hidden launch surfaced the hidden primary.'
  }

  $hiddenActivation = Start-OwnedProcess -FilePath $resolvedExecutablePath
  Assert-ExitedSuccessfully -Process $hiddenActivation `
    -Description 'the interactive activation of a hidden primary'
  Wait-Condition -TimeoutMilliseconds 5000 `
    -Description 'the hidden primary to activate' -Condition {
      [ClockRhythmLifecycleNative]::IsVisible($script:hiddenWindow)
    }
  Stop-PrimaryThroughLifecycleMessage -Process $hiddenPrimary `
    -Window $script:hiddenWindow

  if ($VerifyReadinessRegression) {
    Invoke-ReadinessRegressionProbe
  }

  if ($VerifyFlavorIsolation) {
    Invoke-FlavorIsolationMatrix
  }

  Write-Output `
    'Windows lifecycle launch matrix and exact autostart cleanup passed.'
} finally {
  foreach ($process in $ownedProcesses) {
    if (-not $process.HasExited) {
      $window = [ClockRhythmLifecycleNative]::FindWindow($process.Id)
      if ($window -ne [IntPtr]::Zero) {
        [void][ClockRhythmLifecycleNative]::ExitThroughLifecycleMessage($window)
        [void]$process.WaitForExit(2000)
      }
      if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
      }
    }
    $process.Dispose()
  }
  if ($null -ne (Get-ExactRunRegistration -Name $registrationName)) {
    Remove-ItemProperty -LiteralPath $runRegistryPath `
      -Name $registrationName -ErrorAction SilentlyContinue
  }
  if ($null -ne (Get-ExactRunRegistration -Name $siblingRegistrationName)) {
    Remove-ItemProperty -LiteralPath $runRegistryPath `
      -Name $siblingRegistrationName -ErrorAction SilentlyContinue
  }
  Pop-Location
}
