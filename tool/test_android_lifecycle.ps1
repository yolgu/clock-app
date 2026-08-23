[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,
    [ValidateSet('Beta', 'Production')]
    [string]$Flavor = 'Beta',
    [ValidateSet(
        'Inspect',
        'InstallSmoke',
        'ProcessDeath',
        'ForceStopRecovery',
        'PackageReplacement'
    )]
    [string]$Scenario = 'Inspect',
    [string]$EvidenceDirectory = 'artifacts/evidence/android'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string]$repositoryRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..')
)
[string]$resolvedApkPath = if ([System.IO.Path]::IsPathRooted($ApkPath)) {
    [System.IO.Path]::GetFullPath($ApkPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $ApkPath))
}
if (-not (Test-Path -LiteralPath $resolvedApkPath -PathType Leaf)) {
    throw "Android artifact does not exist: $resolvedApkPath"
}

[string]$adbExecutable = ''
if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) {
    [string]$sdkAdb = Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe'
    if (Test-Path -LiteralPath $sdkAdb -PathType Leaf) {
        $adbExecutable = $sdkAdb
    }
}
if ([string]::IsNullOrWhiteSpace($adbExecutable)) {
    [System.Management.Automation.CommandInfo]$adbCommand =
        Get-Command adb -ErrorAction Stop
    $adbExecutable = $adbCommand.Source
}

function Invoke-AndroidDebugBridge {
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    [System.Management.Automation.ActionPreference]$previousPreference =
        $ErrorActionPreference
    [object[]]$rawOutput = @()
    [int]$exitCode = 0
    try {
        $ErrorActionPreference = 'Continue'
        $rawOutput = @(& $adbExecutable -s $DeviceId @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    [string[]]$output = @(
        $rawOutput | ForEach-Object { $_.ToString() }
    )
    if ($exitCode -ne 0) {
        throw (
            "adb failed with exit code $exitCode for arguments: " +
            ($Arguments -join ' ') + "`n" + ($output -join "`n")
        )
    }
    return $output
}

function Get-AndroidProperty {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return (Invoke-AndroidDebugBridge -Arguments @('shell', 'getprop', $Name) |
        Select-Object -First 1).Trim()
}

function Get-RedactedDeviceIdHash {
    [OutputType([string])]
    param()

    [byte[]]$bytes = [System.Text.Encoding]::UTF8.GetBytes($DeviceId)
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

[string]$deviceState = (
    Invoke-AndroidDebugBridge -Arguments @('get-state') |
        Select-Object -First 1
).Trim()
if ($deviceState -ne 'device') {
    throw "Android target is not ready: $deviceState"
}

[string]$packageId = if ($Flavor -eq 'Beta') {
    'dev.wndls.clockrhythm.beta'
} else {
    'dev.wndls.clockrhythm'
}
[string]$artifactHash = (
    Get-FileHash -LiteralPath $resolvedApkPath -Algorithm SHA256
).Hash.ToLowerInvariant()
[string]$observedAtUtc = [DateTime]::UtcNow.ToString('o')

[System.Collections.Generic.List[string]]$actions =
    [System.Collections.Generic.List[string]]::new()
switch ($Scenario) {
    'Inspect' {
        $actions.Add('No device state was changed.')
    }
    'InstallSmoke' {
        [void](Invoke-AndroidDebugBridge -Arguments @(
            'install', '-r', $resolvedApkPath
        ))
        [void](Invoke-AndroidDebugBridge -Arguments @(
            'shell', 'monkey', '-p', $packageId,
            '-c', 'android.intent.category.LAUNCHER', '1'
        ))
        $actions.Add('Installed the artifact as an in-place update and launched it.')
    }
    'ProcessDeath' {
        [void](Invoke-AndroidDebugBridge -Arguments @(
            'shell', 'am', 'kill', $packageId
        ))
        [void](Invoke-AndroidDebugBridge -Arguments @(
            'shell', 'monkey', '-p', $packageId,
            '-c', 'android.intent.category.LAUNCHER', '1'
        ))
        $actions.Add('Killed the background process and launched the package normally.')
    }
    'ForceStopRecovery' {
        [void](Invoke-AndroidDebugBridge -Arguments @(
            'shell', 'am', 'force-stop', $packageId
        ))
        [void](Invoke-AndroidDebugBridge -Arguments @(
            'shell', 'monkey', '-p', $packageId,
            '-c', 'android.intent.category.LAUNCHER', '1'
        ))
        $actions.Add('Force-stopped the package and then performed an explicit user-style launch.')
    }
    'PackageReplacement' {
        [void](Invoke-AndroidDebugBridge -Arguments @(
            'install', '-r', $resolvedApkPath
        ))
        $actions.Add('Installed the supplied artifact over the existing package.')
    }
}

[string[]]$packageDump = @(
    Invoke-AndroidDebugBridge -Arguments @(
        'shell', 'dumpsys', 'package', $packageId
    )
)
[string[]]$packageSummary = @(
    $packageDump |
        Select-String -Pattern @(
            '^\s*versionName=',
            '^\s*versionCode=',
            'SCHEDULE_EXACT_ALARM',
            'POST_NOTIFICATIONS',
            '^\s*User 0:'
        ) |
        ForEach-Object { $_.Line.Trim() } |
        Select-Object -Unique
)
[string[]]$alarmDump = @(
    Invoke-AndroidDebugBridge -Arguments @('shell', 'dumpsys', 'alarm')
)
[int]$alarmReferenceCount = @(
    $alarmDump | Select-String -SimpleMatch $packageId
).Count
[string[]]$notificationDump = @(
    Invoke-AndroidDebugBridge -Arguments @('shell', 'dumpsys', 'notification')
)
[int]$notificationReferenceCount = @(
    $notificationDump | Select-String -SimpleMatch $packageId
).Count
[string[]]$backupDump = @(
    Invoke-AndroidDebugBridge -Arguments @('shell', 'dumpsys', 'backup')
)
[string[]]$backupSummary = @(
    $backupDump |
        Select-String -Pattern 'Backup Manager is|Current transport|transport:' |
        ForEach-Object { $_.Line.Trim() } |
        Select-Object -First 20
)

[System.Collections.Specialized.OrderedDictionary]$record = [ordered]@{
    schemaVersion = 1
    observedAtUtc = $observedAtUtc
    scenario = $Scenario
    result = 'OperatorAssessmentRequired'
    artifact = [ordered]@{
        basename = [System.IO.Path]::GetFileName($resolvedApkPath)
        sha256 = $artifactHash
        flavor = $Flavor.ToLowerInvariant()
        packageId = $packageId
    }
    environment = [ordered]@{
        apiLevel = [int](Get-AndroidProperty -Name 'ro.build.version.sdk')
        model = Get-AndroidProperty -Name 'ro.product.model'
        buildFingerprint = Get-AndroidProperty -Name 'ro.build.fingerprint'
        deviceIdSha256 = Get-RedactedDeviceIdHash
    }
    actions = [string[]]$actions.ToArray()
    observations = [ordered]@{
        package = $packageSummary
        alarmReferenceCount = $alarmReferenceCount
        notificationReferenceCount = $notificationReferenceCount
        backup = $backupSummary
    }
    operatorAssessment = [ordered]@{
        expectedResultChecked = $false
        pass = $null
        redactedEvidenceReference = $null
        notes = $null
    }
}

[string]$resolvedEvidenceDirectory = if (
    [System.IO.Path]::IsPathRooted($EvidenceDirectory)
) {
    [System.IO.Path]::GetFullPath($EvidenceDirectory)
} else {
    [System.IO.Path]::GetFullPath(
        (Join-Path $repositoryRoot $EvidenceDirectory)
    )
}
[void](New-Item -ItemType Directory -Force -Path $resolvedEvidenceDirectory)
[string]$safeScenario = $Scenario.ToLowerInvariant()
[string]$fileName = '{0}-{1}-api{2}-{3}-{4}.json' -f @(
    [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss'),
    $Flavor.ToLowerInvariant(),
    $record.environment.apiLevel,
    $safeScenario,
    $artifactHash.Substring(0, 12)
)
[string]$recordPath = Join-Path $resolvedEvidenceDirectory $fileName
$record |
    ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $recordPath -Encoding UTF8

Write-Output "Android evidence record: $recordPath"
Write-Output 'The record is observational until operatorAssessment is completed.'
