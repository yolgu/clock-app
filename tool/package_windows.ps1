[CmdletBinding()]
param(
    [ValidateSet('Beta', 'Production')]
    [string]$Flavor = 'Beta',
    [ValidateSet('Zip', 'Msix', 'All')]
    [string]$Artifact = 'Zip',
    [string]$OutputDirectory = 'artifacts\windows',
    [string]$ManifestPath = 'artifacts\manifest.json',
    [switch]$SkipPreflight
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'source_snapshot.ps1')
[string]$repositoryRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..')
)
[string]$sourceSnapshotSha256 = Get-ClockRhythmSourceSnapshotSha256 `
    -RepositoryRoot $repositoryRoot
[string[]]$distributionNotices = @(
    'ASSET_NOTICE.md',
    'THIRD_PARTY_NOTICES.md'
)

$release = if ($Flavor -eq 'Beta') {
    [ordered]@{
        FlavorId = 'beta'
        DisplayName = 'Clock Rhythm Beta'
        VersionName = '0.1.0'
        BuildNumber = 1
        Identity = 'dev.wndls.clockrhythm.beta'
        StartupTaskId = 'ClockRhythmBetaStartup'
    }
} else {
    [ordered]@{
        FlavorId = 'production'
        DisplayName = 'Clock Rhythm'
        VersionName = '1.0.0'
        BuildNumber = 1
        Identity = 'dev.wndls.clockrhythm'
        StartupTaskId = 'ClockRhythmStartup'
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
        throw 'FVM is unavailable. Run the Windows preflight or set CLOCK_RHYTHM_FVM.'
    }
    return $command.Source
}

function Assert-ExternalFile {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description file does not exist."
    }
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $repositoryRoot = [System.IO.Path]::GetFullPath((Get-Location))
    $repositoryRootPrefix =
        $repositoryRoot.TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ) + [System.IO.Path]::DirectorySeparatorChar
    if ($resolvedPath.Equals(
            $repositoryRoot,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -or
        $resolvedPath.StartsWith(
            $repositoryRootPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw "$Description must be stored outside the repository."
    }
    return $resolvedPath
}

function Get-ProductionCertificate {
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE) -or
        [string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD)) {
        throw 'Production Windows MSIX signing credentials are missing: CLOCK_RHYTHM_WINDOWS_CERTIFICATE, CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD.'
    }
    $certificatePath = Assert-ExternalFile `
        $env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE 'Production Windows certificate'
    return [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $certificatePath,
        $env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD
    )
}

function Resolve-WindowsSdkTool {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )

    $windowsKitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
    $versionDirectory = Get-ChildItem -LiteralPath $windowsKitsRoot -Directory `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending |
        Select-Object -First 1
    if ($null -eq $versionDirectory) {
        throw 'Windows SDK tools are unavailable.'
    }
    $toolPath = Join-Path $versionDirectory.FullName "x64\$ToolName"
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "Windows SDK tool is missing: $toolPath"
    }
    return $toolPath
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
        -not (Split-Path -Leaf $resolvedPath).StartsWith('windows-')) {
        throw "Refusing unsafe Windows staging cleanup: $resolvedPath"
    }
    if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
        Remove-Item -LiteralPath $resolvedPath -Recurse -Force
    }
}

function Copy-WindowsBundle {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$Destination
    )

    New-Item -ItemType Directory -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse
    }
}

function New-MsixImage {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$Destination,
        [Parameter(Mandatory)]
        [int]$Width,
        [Parameter(Mandatory)]
        [int]$Height
    )

    Add-Type -AssemblyName System.Drawing
    $sourceImage = [System.Drawing.Image]::FromFile($Source)
    $targetImage = [System.Drawing.Bitmap]::new($Width, $Height)
    try {
        $targetImage.SetResolution(96, 96)
        $graphics = [System.Drawing.Graphics]::FromImage($targetImage)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingQuality = `
                [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = `
                [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = `
                [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.DrawImage($sourceImage, 0, 0, $Width, $Height)
        } finally {
            $graphics.Dispose()
        }
        $targetImage.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $targetImage.Dispose()
        $sourceImage.Dispose()
    }
}

function New-AppxManifest {
    param(
        [Parameter(Mandatory)]
        [string]$Destination,
        [Parameter(Mandatory)]
        [string]$Publisher
    )

    $escapedPublisher = [System.Security.SecurityElement]::Escape($Publisher)
    $escapedDisplayName = [System.Security.SecurityElement]::Escape(
        $release.DisplayName
    )
    $manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:desktop="http://schemas.microsoft.com/appx/manifest/desktop/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap desktop rescap">
  <Identity Name="$($release.Identity)"
            Publisher="$escapedPublisher"
            Version="$($release.VersionName).$($release.BuildNumber)"
            ProcessorArchitecture="x64" />
  <Properties>
    <DisplayName>$escapedDisplayName</DisplayName>
    <PublisherDisplayName>dev.wndls</PublisherDisplayName>
    <Logo>Images\StoreLogo.png</Logo>
    <Description>Local-first focus rhythm and Todo app.</Description>
  </Properties>
  <Resources>
    <Resource Language="en-us" />
    <Resource Language="ko-kr" />
  </Resources>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop"
                        MinVersion="10.0.17763.0"
                        MaxVersionTested="10.0.26100.0" />
  </Dependencies>
  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
  <Applications>
    <Application Id="ClockRhythm"
                 Executable="clock_rhythm.exe"
                 EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="$escapedDisplayName"
                          Description="Local-first focus rhythm and Todo app."
                          BackgroundColor="transparent"
                          Square150x150Logo="Images\Square150x150Logo.png"
                          Square44x44Logo="Images\Square44x44Logo.png" />
      <Extensions>
        <desktop:Extension Category="windows.startupTask"
                           Executable="clock_rhythm.exe"
                           EntryPoint="Windows.FullTrustApplication">
          <desktop:StartupTask TaskId="$($release.StartupTaskId)"
                               Enabled="false"
                               DisplayName="$escapedDisplayName" />
        </desktop:Extension>
      </Extensions>
    </Application>
  </Applications>
</Package>
"@
    $manifest | Set-Content -LiteralPath $Destination -Encoding utf8
}

function New-PortableZip {
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$BundleDirectory,
        [Parameter(Mandatory)]
        [string]$StagingDirectory
    )

    $fileName = "clock-rhythm-$($release.FlavorId)-$($release.VersionName)+$($release.BuildNumber)-windows-x64.zip"
    $stagedArtifact = Join-Path $StagingDirectory $fileName
    Compress-Archive -Path (Join-Path $BundleDirectory '*') `
        -DestinationPath $stagedArtifact -CompressionLevel Optimal
    $verifier = Join-Path $PSScriptRoot 'verify_artifact.ps1'
    & $verifier -Platform Windows -Type PortableZip -Flavor $Flavor `
        -ArtifactPath $stagedArtifact | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    return [pscustomobject]@{
        Type = 'PortableZip'
        Path = $stagedArtifact
        Description = 'Windows portable package'
    }
}

function New-Msix {
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$BundleDirectory,
        [Parameter(Mandatory)]
        [string]$StagingDirectory,
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    $layoutDirectory = Join-Path $StagingDirectory 'msix-layout'
    Copy-WindowsBundle -Source $BundleDirectory -Destination $layoutDirectory
    $imagesDirectory = Join-Path $layoutDirectory 'Images'
    New-Item -ItemType Directory -Path $imagesDirectory | Out-Null
    $sourceIcon = [System.IO.Path]::GetFullPath('assets\images\icon.png')
    New-MsixImage $sourceIcon (Join-Path $imagesDirectory 'StoreLogo.png') 50 50
    New-MsixImage $sourceIcon (Join-Path $imagesDirectory 'Square44x44Logo.png') 44 44
    New-MsixImage $sourceIcon (Join-Path $imagesDirectory 'Square150x150Logo.png') 150 150
    New-AppxManifest -Destination (Join-Path $layoutDirectory 'AppxManifest.xml') `
        -Publisher $Certificate.Subject

    $fileName = "clock-rhythm-production-$($release.VersionName)+$($release.BuildNumber)-windows-x64.msix"
    $stagedArtifact = Join-Path $StagingDirectory $fileName
    $makeAppx = Resolve-WindowsSdkTool 'makeappx.exe'
    & $makeAppx pack /d $layoutDirectory /p $stagedArtifact /o | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $signTool = Resolve-WindowsSdkTool 'signtool.exe'
    & $signTool sign /fd SHA256 `
        /f $env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE `
        /p $env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD `
        $stagedArtifact | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $verifier = Join-Path $PSScriptRoot 'verify_artifact.ps1'
    & $verifier -Platform Windows -Type Msix -Flavor Production `
        -ArtifactPath $stagedArtifact | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    return [pscustomobject]@{
        Type = 'Msix'
        Path = $stagedArtifact
        Description = 'Windows MSIX package'
    }
}

function Publish-StagedArtifacts {
    param(
        [Parameter(Mandatory)]
        [object[]]$Artifacts,
        [Parameter(Mandatory)]
        [string]$OutputRoot
    )

    $verifier = Join-Path $PSScriptRoot 'verify_artifact.ps1'
    foreach ($staged in $Artifacts) {
        $finalArtifact = Join-Path $OutputRoot (Split-Path -Leaf $staged.Path)
        Copy-Item -LiteralPath $staged.Path -Destination $finalArtifact -Force
        & $verifier -Platform Windows -Type $staged.Type -Flavor $Flavor `
            -ArtifactPath $finalArtifact -ManifestPath $ManifestPath `
            -SourceSnapshotSha256 $sourceSnapshotSha256 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Write-Output "$($staged.Description): $finalArtifact"
    }
}

if ($Flavor -eq 'Beta' -and $Artifact -ne 'Zip') {
    throw 'Beta distribution produces a portable Windows ZIP; MSIX is production-only.'
}

$certificate = $null
if ($Artifact -in @('Msix', 'All')) {
    if ($Flavor -ne 'Production') {
        throw 'MSIX packaging requires the production flavor.'
    }
    $certificate = Get-ProductionCertificate
}

if (-not $SkipPreflight) {
    & (Join-Path $PSScriptRoot 'preflight.ps1') -Platform Windows
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
$fvmExecutable = Resolve-FvmExecutable
$nativeHarness = Join-Path $PSScriptRoot 'test_windows_lifecycle.ps1'

Write-Output 'Resolving the locked dependency graph.'
& $fvmExecutable flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $nativeHarness -Flavor $release.FlavorId `
    -VerifyFlavorIsolation -VerifyReadinessRegression
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$previousFlavor = $env:CLOCK_RHYTHM_WINDOWS_FLAVOR
try {
    $env:CLOCK_RHYTHM_WINDOWS_FLAVOR = $release.FlavorId
    Write-Output "Building the $Flavor Windows release bundle."
    & $fvmExecutable flutter build windows `
        --release `
        --no-pub `
        --build-name $release.VersionName `
        --build-number $release.BuildNumber `
        "--dart-define=CLOCK_RHYTHM_FLAVOR=$($release.FlavorId)"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    $env:CLOCK_RHYTHM_WINDOWS_FLAVOR = $previousFlavor
}

$releaseDirectory = [System.IO.Path]::GetFullPath(
    'build\windows\x64\runner\Release'
)
if (-not (Test-Path -LiteralPath $releaseDirectory -PathType Container)) {
    throw "Expected Windows release bundle is missing: $releaseDirectory"
}
& $nativeHarness `
    -ExecutablePath (Join-Path $releaseDirectory 'clock_rhythm.exe') `
    -Flavor $release.FlavorId `
    -SkipFlutterBuild
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
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
    "windows-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $stagingDirectory | Out-Null
$bundleDirectory = Join-Path $stagingDirectory 'bundle'

try {
    Copy-WindowsBundle -Source $releaseDirectory -Destination $bundleDirectory
    foreach ($notice in $distributionNotices) {
        [string]$noticeSource = Join-Path $repositoryRoot $notice
        if (-not (Test-Path -LiteralPath $noticeSource -PathType Leaf)) {
            throw "Required distribution notice is missing: $notice"
        }
        Copy-Item -LiteralPath $noticeSource -Destination $bundleDirectory
    }
    $stagedArtifacts = [System.Collections.Generic.List[object]]::new()
    if ($Artifact -in @('Zip', 'All')) {
        $stagedArtifacts.Add(
            (New-PortableZip -BundleDirectory $bundleDirectory `
                -StagingDirectory $stagingDirectory)
        )
    }
    if ($Artifact -in @('Msix', 'All')) {
        $stagedArtifacts.Add(
            (New-Msix -BundleDirectory $bundleDirectory `
                -StagingDirectory $stagingDirectory -Certificate $certificate)
        )
    }
    Publish-StagedArtifacts -Artifacts $stagedArtifacts.ToArray() `
        -OutputRoot $outputRoot
} finally {
    Remove-OwnedStagingDirectory -Path $stagingDirectory `
        -StagingRoot $stagingRoot
    if ($null -ne $certificate) {
        $certificate.Dispose()
    }
}
