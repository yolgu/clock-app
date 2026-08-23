[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Android', 'Windows')]
    [string]$Platform,
    [Parameter(Mandatory)]
    [ValidateSet('Apk', 'AppBundle', 'PortableZip', 'Msix')]
    [string]$Type,
    [Parameter(Mandatory)]
    [ValidateSet('Beta', 'Production')]
    [string]$Flavor,
    [Parameter(Mandatory)]
    [string]$ArtifactPath,
    [string]$ManifestPath,
    [string]$SourceSnapshotSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$androidXmlNamespace = 'http://schemas.android.com/apk/res/android'
$expected = if ($Flavor -eq 'Beta') {
    [ordered]@{
        Flavor = 'beta'
        DisplayName = 'Clock Rhythm Beta'
        VersionName = '0.1.0'
        BuildNumber = 1
        Identity = 'dev.wndls.clockrhythm.beta'
        WindowsStartupTaskId = 'ClockRhythmBetaStartup'
    }
} else {
    [ordered]@{
        Flavor = 'production'
        DisplayName = 'Clock Rhythm'
        VersionName = '1.0.0'
        BuildNumber = 1
        Identity = 'dev.wndls.clockrhythm'
        WindowsStartupTaskId = 'ClockRhythmStartup'
    }
}

function Assert-Equal {
    param(
        [Parameter(Mandatory)]
        [object]$Expected,
        [Parameter(Mandatory)]
        [object]$Actual,
        [Parameter(Mandatory)]
        [string]$Description
    )

    if ($Expected -ne $Actual) {
        throw "$Description mismatch. Expected <$Expected>, found <$Actual>."
    }
}

function Invoke-CapturedCommand {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Executable,
        [Parameter(Mandatory)]
        [string[]]$Arguments,
        [Parameter(Mandatory)]
        [string]$Description
    )

    [System.Management.Automation.ActionPreference]$previousPreference =
        $ErrorActionPreference
    [object[]]$commandOutput = @()
    [int]$commandExitCode = 0
    try {
        $ErrorActionPreference = 'Continue'
        $commandOutput = @(& $Executable @Arguments 2>&1)
        $commandExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    [string]$output = (
        $commandOutput |
            ForEach-Object { $_.ToString() } |
            Out-String
    ).Trim()
    if ($commandExitCode -ne 0) {
        throw "$Description failed with exit code $commandExitCode.`n$output"
    }
    return $output
}

function Resolve-AndroidSdkPath {
    [OutputType([string])]
    param()

    $candidate = if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) {
        $env:ANDROID_SDK_ROOT
    } elseif (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        $env:ANDROID_HOME
    } else {
        ''
    }
    if ([string]::IsNullOrWhiteSpace($candidate) -or
        -not (Test-Path -LiteralPath $candidate -PathType Container)) {
        throw 'Android SDK path is unavailable. Set ANDROID_SDK_ROOT or ANDROID_HOME.'
    }
    return [System.IO.Path]::GetFullPath($candidate)
}

function Resolve-BuildTool {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )

    $sdkPath = Resolve-AndroidSdkPath
    $toolPath = Join-Path $sdkPath "build-tools\36.0.0\$ToolName"
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "Android Build Tools 36.0.0 tool is missing: $toolPath"
    }
    return $toolPath
}

function Resolve-ApkAnalyzer {
    [OutputType([string])]
    param()

    $sdkPath = Resolve-AndroidSdkPath
    $toolPath = Join-Path $sdkPath 'cmdline-tools\latest\bin\apkanalyzer.bat'
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "Android APK Analyzer is missing: $toolPath"
    }
    return $toolPath
}

function Resolve-JavaTool {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )

    if ([string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
        throw 'JAVA_HOME is required for Android App Bundle inspection.'
    }
    $toolPath = Join-Path $env:JAVA_HOME "bin\$ToolName"
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "Java tool is missing: $toolPath"
    }
    return $toolPath
}

function Resolve-BundleTool {
    [OutputType([string])]
    param()

    $versionsRoot = Join-Path $env:USERPROFILE `
        '.gradle\caches\modules-2\files-2.1\com.android.tools.build\bundletool'
    $versionDirectory = Get-ChildItem -LiteralPath $versionsRoot -Directory `
        -ErrorAction SilentlyContinue |
        Sort-Object { [version]$_.Name } -Descending |
        Select-Object -First 1
    if ($null -eq $versionDirectory) {
        throw 'Gradle bundletool dependency is unavailable. Run the Android build first.'
    }
    $bundleTool = Get-ChildItem -LiteralPath $versionDirectory.FullName `
        -Recurse -Filter 'bundletool-*.jar' -File |
        Select-Object -First 1
    if ($null -eq $bundleTool) {
        throw "bundletool jar is unavailable under $($versionDirectory.FullName)."
    }
    return $bundleTool.FullName
}

function Get-ZipEntryNames {
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        return @(
            $archive.Entries |
            Where-Object { -not [string]::IsNullOrEmpty($_.Name) } |
            ForEach-Object { $_.FullName.Replace('\', '/') }
        )
    } finally {
        $archive.Dispose()
    }
}

function Get-ZipEntryText {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$EntryName
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $archive.Entries | Where-Object {
            $_.FullName.Replace('\', '/') -eq $EntryName
        } | Select-Object -First 1
        if ($null -eq $entry) {
            throw "Archive entry is missing: $EntryName"
        }
        $reader = [System.IO.StreamReader]::new($entry.Open())
        try {
            return $reader.ReadToEnd()
        } finally {
            $reader.Dispose()
        }
    } finally {
        $archive.Dispose()
    }
}

function Copy-ZipEntryToTemporaryFile {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$EntryName,
        [Parameter(Mandatory)]
        [string]$Extension
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) `
        "clock-rhythm-inspection-$([guid]::NewGuid().ToString('N'))$Extension"
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $archive.Entries | Where-Object {
            $_.FullName.Replace('\', '/') -eq $EntryName
        } | Select-Object -First 1
        if ($null -eq $entry) {
            throw "Archive entry is missing: $EntryName"
        }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile(
            $entry,
            $temporaryPath,
            $false
        )
        return $temporaryPath
    } finally {
        $archive.Dispose()
    }
}

function Assert-RequiredArchiveEntries {
    param(
        [Parameter(Mandatory)]
        [string[]]$Entries,
        [Parameter(Mandatory)]
        [string[]]$RequiredEntries
    )

    $missingEntries = @($RequiredEntries | Where-Object { $_ -notin $Entries })
    if ($missingEntries.Count -gt 0) {
        throw "Artifact is missing required files: $($missingEntries -join ', ')."
    }
}

function Get-ExternalWindowsCertificateDigest {
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE) -or
        [string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD)) {
        throw 'Production Windows artifact verification requires CLOCK_RHYTHM_WINDOWS_CERTIFICATE and CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD.'
    }
    if (-not (Test-Path -LiteralPath $env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE -PathType Leaf)) {
        throw 'Production Windows certificate file does not exist.'
    }
    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE,
        $env:CLOCK_RHYTHM_WINDOWS_CERTIFICATE_PASSWORD
    )
    try {
        return $certificate.GetCertHashString(
            [System.Security.Cryptography.HashAlgorithmName]::SHA256
        ).ToLowerInvariant()
    } finally {
        $certificate.Dispose()
    }
}

function Get-ExternalAndroidCertificateDigest {
    [OutputType([string])]
    param()

    if ([string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_ANDROID_KEYSTORE) -or
        [string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_ANDROID_KEY_ALIAS) -or
        [string]::IsNullOrWhiteSpace($env:CLOCK_RHYTHM_ANDROID_STORE_PASSWORD)) {
        throw 'Production Android artifact verification requires the external keystore, alias, and store password.'
    }
    $keyTool = Resolve-JavaTool -ToolName 'keytool.exe'
    $output = Invoke-CapturedCommand -Executable $keyTool -Arguments @(
        '-list', '-v',
        '-keystore', $env:CLOCK_RHYTHM_ANDROID_KEYSTORE,
        '-alias', $env:CLOCK_RHYTHM_ANDROID_KEY_ALIAS,
        '-storepass:env', 'CLOCK_RHYTHM_ANDROID_STORE_PASSWORD'
    ) -Description 'Production Android certificate inspection'
    $match = [regex]::Match($output, 'SHA256:\s*([0-9A-F:]{64,})', 'IgnoreCase')
    if (-not $match.Success) {
        throw 'Production Android certificate SHA-256 digest was not reported.'
    }
    return $match.Groups[1].Value.Replace(':', '').ToLowerInvariant()
}

function Inspect-AndroidApk {
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $analyzer = Resolve-ApkAnalyzer
    $applicationId = Invoke-CapturedCommand $analyzer @(
        'manifest', 'application-id', $Path
    ) 'APK application ID inspection'
    $versionName = Invoke-CapturedCommand $analyzer @(
        'manifest', 'version-name', $Path
    ) 'APK version-name inspection'
    $versionCode = Invoke-CapturedCommand $analyzer @(
        'manifest', 'version-code', $Path
    ) 'APK version-code inspection'
    $minSdk = Invoke-CapturedCommand $analyzer @(
        'manifest', 'min-sdk', $Path
    ) 'APK min-SDK inspection'
    $targetSdk = Invoke-CapturedCommand $analyzer @(
        'manifest', 'target-sdk', $Path
    ) 'APK target-SDK inspection'
    $debuggable = Invoke-CapturedCommand $analyzer @(
        'manifest', 'debuggable', $Path
    ) 'APK debuggable inspection'

    Assert-Equal $expected.Identity $applicationId 'Android application ID'
    Assert-Equal $expected.VersionName $versionName 'Android version name'
    Assert-Equal $expected.BuildNumber ([int]$versionCode) 'Android version code'
    Assert-Equal 24 ([int]$minSdk) 'Android minimum SDK'
    Assert-Equal 36 ([int]$targetSdk) 'Android target SDK'
    Assert-Equal 'false' $debuggable.ToLowerInvariant() 'Android debuggable flag'

    $entries = Get-ZipEntryNames $Path
    $architectures = @(
        $entries |
        ForEach-Object {
            $match = [regex]::Match($_, '^lib/([^/]+)/libapp\.so$')
            if ($match.Success) { $match.Groups[1].Value }
        } |
        Sort-Object -Unique
    )
    @('armeabi-v7a', 'arm64-v8a').ForEach({
        if ($_ -notin $architectures) {
            throw "APK is missing required release architecture: $_."
        }
    })
    $requiredFiles = @(
        'assets/flutter_assets/AssetManifest.bin',
        'assets/flutter_assets/assets/audio/CHIME14.mp3'
    )
    Assert-RequiredArchiveEntries $entries $requiredFiles

    $apkSigner = Resolve-BuildTool -ToolName 'apksigner.bat'
    $signatureOutput = Invoke-CapturedCommand $apkSigner @(
        'verify', '--verbose', '--print-certs', $Path
    ) 'APK signature verification'
    $digestMatch = [regex]::Match(
        $signatureOutput,
        'certificate SHA-256 digest:\s*([0-9a-f:]{64,})',
        'IgnoreCase'
    )
    if (-not $digestMatch.Success) {
        throw 'APK signer SHA-256 digest was not reported.'
    }
    $certificateDigest = $digestMatch.Groups[1].Value.Replace(':', '').ToLowerInvariant()
    if ($Flavor -eq 'Production') {
        Assert-Equal (Get-ExternalAndroidCertificateDigest) $certificateDigest `
            'Production Android signing certificate'
    }

    return @{
        Identity = $applicationId
        VersionName = $versionName
        BuildNumber = [int]$versionCode
        Architectures = $architectures
        SigningStatus = if ($Flavor -eq 'Beta') { 'development' } else { 'production' }
        CertificateDigest = $certificateDigest
        Inspection = [ordered]@{
            minSdk = [int]$minSdk
            targetSdk = [int]$targetSdk
            requiredFiles = $requiredFiles
        }
    }
}

function Inspect-AndroidAppBundle {
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($Flavor -ne 'Production') {
        throw 'Android App Bundle is a production-only artifact contract.'
    }
    $java = Resolve-JavaTool -ToolName 'java.exe'
    $bundleTool = Resolve-BundleTool
    $manifestText = Invoke-CapturedCommand $java @(
        '-jar', $bundleTool, 'dump', 'manifest', "--bundle=$Path", '--module=base'
    ) 'Android App Bundle manifest inspection'
    [xml]$manifest = $manifestText
    $manifestRoot = $manifest.DocumentElement
    $usesSdk = $manifestRoot.SelectSingleNode("*[local-name()='uses-sdk']")
    if ($null -eq $usesSdk) {
        throw 'Android App Bundle manifest has no uses-sdk element.'
    }
    $applicationId = $manifestRoot.GetAttribute('package')
    $versionName = $manifestRoot.GetAttribute('versionName', $androidXmlNamespace)
    $versionCode = [int]$manifestRoot.GetAttribute('versionCode', $androidXmlNamespace)
    $minSdk = [int]$usesSdk.GetAttribute('minSdkVersion', $androidXmlNamespace)
    $targetSdk = [int]$usesSdk.GetAttribute('targetSdkVersion', $androidXmlNamespace)

    Assert-Equal $expected.Identity $applicationId 'Android application ID'
    Assert-Equal $expected.VersionName $versionName 'Android version name'
    Assert-Equal $expected.BuildNumber $versionCode 'Android version code'
    Assert-Equal 24 $minSdk 'Android minimum SDK'
    Assert-Equal 36 $targetSdk 'Android target SDK'

    $entries = Get-ZipEntryNames $Path
    $architectures = @(
        $entries |
        ForEach-Object {
            $match = [regex]::Match($_, '^base/lib/([^/]+)/libapp\.so$')
            if ($match.Success) { $match.Groups[1].Value }
        } |
        Sort-Object -Unique
    )
    @('armeabi-v7a', 'arm64-v8a').ForEach({
        if ($_ -notin $architectures) {
            throw "Android App Bundle is missing required release architecture: $_."
        }
    })
    $requiredFiles = @(
        'base/manifest/AndroidManifest.xml',
        'base/assets/flutter_assets/AssetManifest.bin',
        'base/assets/flutter_assets/assets/audio/CHIME14.mp3'
    )
    Assert-RequiredArchiveEntries $entries $requiredFiles

    $jarSigner = Resolve-JavaTool -ToolName 'jarsigner.exe'
    Invoke-CapturedCommand $jarSigner @('-verify', '-strict', $Path) `
        'Android App Bundle signature verification' | Out-Null
    $keyTool = Resolve-JavaTool -ToolName 'keytool.exe'
    $certificateOutput = Invoke-CapturedCommand $keyTool @(
        '-printcert', '-jarfile', $Path
    ) 'Android App Bundle signer inspection'
    $digestMatch = [regex]::Match(
        $certificateOutput,
        'SHA256:\s*([0-9A-F:]{64,})',
        'IgnoreCase'
    )
    if (-not $digestMatch.Success) {
        throw 'Android App Bundle signer SHA-256 digest was not reported.'
    }
    $certificateDigest = $digestMatch.Groups[1].Value.Replace(':', '').ToLowerInvariant()
    Assert-Equal (Get-ExternalAndroidCertificateDigest) $certificateDigest `
        'Production Android signing certificate'

    return @{
        Identity = $applicationId
        VersionName = $versionName
        BuildNumber = $versionCode
        Architectures = $architectures
        SigningStatus = 'production'
        CertificateDigest = $certificateDigest
        Inspection = [ordered]@{
            minSdk = $minSdk
            targetSdk = $targetSdk
            requiredFiles = $requiredFiles
        }
    }
}

function Inspect-WindowsArchive {
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [bool]$IsMsix
    )

    $entries = Get-ZipEntryNames $Path
    $requiredRuntimeFiles = @(
        'clock_rhythm.exe',
        'flutter_windows.dll',
        'audioplayers_windows_plugin.dll',
        'flutter_local_notifications_windows.dll',
        'screen_retriever_windows_plugin.dll',
        'sqlite3.dll',
        'tray_manager_plugin.dll',
        'window_manager_plugin.dll',
        'data/app.so',
        'data/icudtl.dat',
        'data/flutter_assets/AssetManifest.bin',
        'data/flutter_assets/assets/audio/CHIME14.mp3'
    )
    $requiredFiles = if ($IsMsix) {
        @($requiredRuntimeFiles + @('AppxManifest.xml', 'AppxBlockMap.xml', '[Content_Types].xml'))
    } else {
        $requiredRuntimeFiles
    }
    Assert-RequiredArchiveEntries $entries $requiredFiles

    $temporaryExecutable = Copy-ZipEntryToTemporaryFile $Path 'clock_rhythm.exe' '.exe'
    try {
        $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo(
            $temporaryExecutable
        )
        Assert-Equal "$($expected.VersionName)+$($expected.BuildNumber)" `
            $versionInfo.ProductVersion `
            'Windows product version'
        Assert-Equal $expected.DisplayName $versionInfo.ProductName `
            'Windows product name'
        $binaryText = [System.Text.Encoding]::ASCII.GetString(
            [System.IO.File]::ReadAllBytes($temporaryExecutable)
        )
        if (-not $binaryText.Contains($expected.Identity)) {
            throw 'Windows executable does not contain the expected compiled identity.'
        }
    } finally {
        if (Test-Path -LiteralPath $temporaryExecutable -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryExecutable -Force
        }
    }

    $certificateDigest = $null
    $signingStatus = 'unsigned'
    if ($IsMsix) {
        if ($Flavor -ne 'Production') {
            throw 'MSIX is a production-only artifact contract.'
        }
        [xml]$appxManifest = Get-ZipEntryText $Path 'AppxManifest.xml'
        $identity = $appxManifest.DocumentElement.SelectSingleNode(
            "*[local-name()='Identity']"
        )
        $application = $appxManifest.DocumentElement.SelectSingleNode(
            "*[local-name()='Applications']/*[local-name()='Application']"
        )
        $startupTask = $appxManifest.DocumentElement.SelectSingleNode(
            "//*[local-name()='StartupTask']"
        )
        if ($null -eq $identity -or $null -eq $application -or $null -eq $startupTask) {
            throw 'MSIX manifest is missing identity, application, or StartupTask.'
        }
        Assert-Equal $expected.Identity $identity.Name 'MSIX package identity'
        Assert-Equal "$($expected.VersionName).$($expected.BuildNumber)" `
            $identity.Version 'MSIX version'
        Assert-Equal 'x64' $identity.ProcessorArchitecture 'MSIX architecture'
        Assert-Equal 'clock_rhythm.exe' $application.Executable `
            'MSIX executable'
        Assert-Equal $expected.WindowsStartupTaskId $startupTask.TaskId `
            'MSIX StartupTask ID'

        $signature = Get-AuthenticodeSignature -LiteralPath $Path
        if ($null -eq $signature.SignerCertificate -or
            $signature.Status -eq [System.Management.Automation.SignatureStatus]::NotSigned -or
            $signature.Status -eq [System.Management.Automation.SignatureStatus]::HashMismatch) {
            throw "MSIX signature is invalid: $($signature.Status)."
        }
        $certificateDigest = $signature.SignerCertificate.GetCertHashString(
            [System.Security.Cryptography.HashAlgorithmName]::SHA256
        ).ToLowerInvariant()
        Assert-Equal (Get-ExternalWindowsCertificateDigest) $certificateDigest `
            'Production Windows signing certificate'
        $signingStatus = 'production'
    }

    return @{
        Identity = $expected.Identity
        VersionName = $expected.VersionName
        BuildNumber = $expected.BuildNumber
        Architectures = @('x64')
        SigningStatus = $signingStatus
        CertificateDigest = $certificateDigest
        Inspection = [ordered]@{
            requiredFiles = $requiredFiles
        }
    }
}

function Update-ArtifactManifest {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Record,
        [Parameter(Mandatory)]
        [string]$SourceSnapshot
    )

    $manifestFullPath = [System.IO.Path]::GetFullPath($Path)
    $manifestDirectory = Split-Path -Parent $manifestFullPath
    if (-not (Test-Path -LiteralPath $manifestDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $manifestDirectory | Out-Null
    }
    $records = @()
    if (Test-Path -LiteralPath $manifestFullPath -PathType Leaf) {
        $existing = Get-Content -Raw -LiteralPath $manifestFullPath | ConvertFrom-Json
        Assert-Equal 1 ([int]$existing.schemaVersion) 'Artifact manifest schema version'
        $sourceSnapshotProperty = $existing.PSObject.Properties[
            'sourceSnapshotSha256'
        ]
        if ($null -ne $sourceSnapshotProperty -and
            $sourceSnapshotProperty.Value -eq $SourceSnapshot) {
            $records = @(
                $existing.artifacts |
                    Where-Object { $_.path -ne $Record.path }
            )
        }
    }
    $records += [pscustomobject]$Record
    $manifest = [ordered]@{
        schemaVersion = 1
        product = 'Clock Rhythm'
        generatedAtUtc = [datetime]::UtcNow.ToString('o')
        sourceSnapshotSha256 = $SourceSnapshot
        artifacts = @($records | Sort-Object path)
    }
    $temporaryManifest = "$manifestFullPath.tmp"
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath `
        $temporaryManifest -Encoding utf8
    Move-Item -LiteralPath $temporaryManifest -Destination $manifestFullPath -Force

    $checksumPath = Join-Path $manifestDirectory 'SHA256SUMS.txt'
    $checksumLines = @(
        $manifest.artifacts |
        Sort-Object path |
        ForEach-Object { "$($_.sha256)  $($_.path.Replace('\', '/'))" }
    )
    $checksumLines | Set-Content -LiteralPath $checksumPath -Encoding utf8
}

$artifactFullPath = [System.IO.Path]::GetFullPath($ArtifactPath)
if (-not (Test-Path -LiteralPath $artifactFullPath -PathType Leaf)) {
    throw "Artifact does not exist: $artifactFullPath"
}

$inspection = switch ("$Platform/$Type") {
    'Android/Apk' { Inspect-AndroidApk $artifactFullPath; break }
    'Android/AppBundle' { Inspect-AndroidAppBundle $artifactFullPath; break }
    'Windows/PortableZip' { Inspect-WindowsArchive $artifactFullPath $false; break }
    'Windows/Msix' { Inspect-WindowsArchive $artifactFullPath $true; break }
    default { throw "$Type is not a valid $Platform artifact type." }
}

$hash = (Get-FileHash -LiteralPath $artifactFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
$file = Get-Item -LiteralPath $artifactFullPath
$artifactType = switch ($Type) {
    'Apk' { 'apk' }
    'AppBundle' { 'aab' }
    'PortableZip' { 'portableZip' }
    'Msix' { 'msix' }
}
$recordPath = $file.Name
if (-not [string]::IsNullOrWhiteSpace($ManifestPath)) {
    $manifestDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($ManifestPath))
    $manifestDirectoryPrefix =
        $manifestDirectory.TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $artifactFullPath.StartsWith(
            $manifestDirectoryPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'Recorded artifact must stay inside the manifest directory.'
    }
    $recordPath = $artifactFullPath.Substring(
        $manifestDirectoryPrefix.Length
    ).Replace('\', '/')
}
$record = [ordered]@{
    path = $recordPath
    platform = $Platform.ToLowerInvariant()
    type = $artifactType
    flavor = $expected.Flavor
    versionName = $inspection.VersionName
    buildNumber = $inspection.BuildNumber
    identity = $inspection.Identity
    architectures = @($inspection.Architectures)
    sha256 = $hash
    sizeBytes = [long]$file.Length
    signing = [ordered]@{
        status = $inspection.SigningStatus
        certificateSha256 = $inspection.CertificateDigest
    }
    inspection = $inspection.Inspection
}
if (-not [string]::IsNullOrWhiteSpace($ManifestPath)) {
    if ($SourceSnapshotSha256 -notmatch '^[0-9a-f]{64}$') {
        throw 'Manifest recording requires a lowercase source snapshot SHA-256.'
    }
    Update-ArtifactManifest $ManifestPath $record $SourceSnapshotSha256
}

Write-Output "Verified $($expected.Flavor) $artifactType artifact: $artifactFullPath"
Write-Output "SHA-256: $hash"
