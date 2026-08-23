[CmdletBinding()]
param(
    [ValidateSet('Beta', 'Production')]
    [string]$ReleaseTier = 'Production'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'source_snapshot.ps1')

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$failures = [System.Collections.Generic.List[string]]::new()
$requiredEvidencePaths = [string[]]@(
    'docs/verification/release-evidence-index.md',
    'docs/verification/legacy-behavior-matrix.md',
    'docs/verification/windows-matrix.md',
    'docs/verification/android-matrix.md',
    'docs/verification/backup-roundtrip.md',
    'docs/verification/installed-update.md',
    'artifacts/manifest.json'
)

foreach ($relativePath in $requiredEvidencePaths) {
    $absolutePath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        $failures.Add("Missing release evidence: $relativePath")
    }
}

$indexPath = Join-Path $repositoryRoot 'docs/verification/release-evidence-index.md'
if (Test-Path -LiteralPath $indexPath -PathType Leaf) {
    $index = Get-Content -LiteralPath $indexPath -Raw
    if ($index -notmatch '(?m)^- Common automated gate: Passed\b') {
        $failures.Add('The current common automated gate is not recorded as Passed.')
    }
    if ($index -notmatch '(?m)^- Known blockers: Documented\b') {
        $failures.Add('Known release blockers are not documented.')
    }
    if ($ReleaseTier -eq 'Beta' -and $index -notmatch '(?m)^- Release decision: Beta\b') {
        $failures.Add('The release decision is not Beta.')
    }
}

$legacyPath = Join-Path $repositoryRoot 'docs/verification/legacy-behavior-matrix.md'
if (Test-Path -LiteralPath $legacyPath -PathType Leaf) {
    $legacyRows = [string[]]@(
        Get-Content -LiteralPath $legacyPath |
            Where-Object { $_ -match '^\|\s*LB-\d{3}\s*\|' }
    )
    if ($legacyRows.Count -ne 182) {
        $failures.Add("Legacy matrix has $($legacyRows.Count) rows; expected 182.")
    }
    for ($index = 0; $index -lt $legacyRows.Count; $index += 1) {
        $expectedId = 'LB-{0:D3}' -f ($index + 1)
        $columns = [string[]]@($legacyRows[$index].Split('|'))
        if ($columns.Count -lt 7 -or $columns[1].Trim() -ne $expectedId) {
            $failures.Add("Legacy matrix row $($index + 1) must be $expectedId.")
            continue
        }
        if ($columns[4].Trim() -notmatch '^P\d+$') {
            $failures.Add("Legacy matrix $expectedId has no valid owning P-item.")
        }
    }
    $invalidStatusRows = [string[]]@(
        $legacyRows | Where-Object {
            [regex]::Matches(
                $_,
                '\b(?:Pending|Verified|Dispositioned)\b'
            ).Count -ne 1
        }
    )
    if ($invalidStatusRows.Count -gt 0) {
        $failures.Add(
            "Legacy matrix has $($invalidStatusRows.Count) rows without exactly one recognized status."
        )
    }
    $unjustifiedDispositionRows = [string[]]@(
        $legacyRows | Where-Object {
            $_ -match '\bDispositioned\b' -and $_ -notmatch '\bADR\s+\d{4}\b'
        }
    )
    if ($unjustifiedDispositionRows.Count -gt 0) {
        $failures.Add(
            "Legacy matrix has $($unjustifiedDispositionRows.Count) dispositions without an ADR reference."
        )
    }
    foreach ($verifiedRow in [string[]]@(
        $legacyRows | Where-Object { $_ -match '\bVerified\b' }
    )) {
        $evidencePaths = [System.Collections.Generic.List[string]]::new()
        foreach ($match in [regex]::Matches(
            $verifiedRow,
            '`((?:test|tool|windows|android)/[^`]+)`'
        )) {
            $evidencePaths.Add($match.Groups[1].Value)
        }
        if ($evidencePaths.Count -eq 0) {
            $failures.Add('A Verified legacy row has no repository evidence path.')
            continue
        }
        foreach ($evidencePath in $evidencePaths) {
            $absoluteEvidencePath = Join-Path $repositoryRoot $evidencePath
            if (-not (Test-Path -LiteralPath $absoluteEvidencePath -PathType Leaf)) {
                $failures.Add("Legacy evidence path is missing: $evidencePath")
            }
        }
    }
    if ($ReleaseTier -eq 'Production') {
        $pendingLegacyRows = [string[]]@(
            $legacyRows | Where-Object { $_ -match '\bPending\b' }
        )
        if ($pendingLegacyRows.Count -gt 0) {
            $failures.Add("Legacy matrix still has $($pendingLegacyRows.Count) Pending rows.")
        }
    }
}

if ($ReleaseTier -eq 'Production') {
    foreach ($relativePath in [string[]]@(
        'docs/verification/windows-matrix.md',
        'docs/verification/android-matrix.md',
        'docs/verification/backup-roundtrip.md',
        'docs/verification/installed-update.md'
    )) {
        $absolutePath = Join-Path $repositoryRoot $relativePath
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            continue
        }
        $content = Get-Content -LiteralPath $absolutePath -Raw
        if ($content -match '\b(Pending|Blocked|Not run)\b') {
            $failures.Add("Production evidence is incomplete: $relativePath")
        }
    }
}

$manifestPath = Join-Path $repositoryRoot 'artifacts/manifest.json'
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        if ($manifest.schemaVersion -ne 1) {
            $failures.Add('Artifact manifest schemaVersion must be 1.')
        }
        $currentSourceSnapshot = Get-ClockRhythmSourceSnapshotSha256 `
            -RepositoryRoot $repositoryRoot
        $manifestSourceProperty = $manifest.PSObject.Properties[
            'sourceSnapshotSha256'
        ]
        if ($null -eq $manifestSourceProperty -or
            $manifestSourceProperty.Value -ne $currentSourceSnapshot) {
            $failures.Add('Artifact manifest does not match the current source snapshot.')
        }
        $artifacts = [object[]]@($manifest.artifacts)
        $requiredArtifacts = if ($ReleaseTier -eq 'Beta') {
            [object[]]@(
                [pscustomobject]@{ Platform = 'windows'; Type = 'portableZip' },
                [pscustomobject]@{ Platform = 'android'; Type = 'apk' }
            )
        } else {
            [object[]]@(
                [pscustomobject]@{ Platform = 'windows'; Type = 'portableZip' },
                [pscustomobject]@{ Platform = 'windows'; Type = 'msix' },
                [pscustomobject]@{ Platform = 'android'; Type = 'apk' },
                [pscustomobject]@{ Platform = 'android'; Type = 'aab' }
            )
        }
        $expectedFlavor = $ReleaseTier.ToLowerInvariant()
        foreach ($requiredArtifact in $requiredArtifacts) {
            $matching = [object[]]@(
                $artifacts | Where-Object {
                    $_.platform -eq $requiredArtifact.Platform -and
                    $_.type -eq $requiredArtifact.Type -and
                    $_.flavor -eq $expectedFlavor
                }
            )
            if ($matching.Count -ne 1) {
                $failures.Add(
                    "Expected exactly one $expectedFlavor $($requiredArtifact.Platform) " +
                    "$($requiredArtifact.Type) artifact; found $($matching.Count)."
                )
                continue
            }
            $artifact = $matching[0]
            if ($artifact.sha256 -notmatch '^[0-9a-f]{64}$') {
                $failures.Add("Artifact hash is invalid: $($artifact.path)")
                continue
            }
            $manifestDirectory = Split-Path -Parent $manifestPath
            $artifactPath = [System.IO.Path]::GetFullPath(
                (Join-Path $manifestDirectory ([string]$artifact.path))
            )
            if (-not $artifactPath.StartsWith(
                $repositoryRoot + [System.IO.Path]::DirectorySeparatorChar,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                $failures.Add("Artifact path escapes the repository: $($artifact.path)")
                continue
            }
            if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
                $failures.Add("Artifact file is missing: $($artifact.path)")
                continue
            }
            $actualHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actualHash -ne $artifact.sha256) {
                $failures.Add("Artifact hash does not match: $($artifact.path)")
            }
            if ($ReleaseTier -eq 'Production' -and
                $requiredArtifact.Type -in [string[]]@('msix', 'apk', 'aab') -and
                $artifact.signing.status -ne 'production') {
                $failures.Add("Production artifact is not production signed: $($artifact.path)")
            }
        }
    } catch {
        $failures.Add("Artifact manifest is invalid: $($_.Exception.GetType().Name)")
    }
}

if ($failures.Count -gt 0) {
    Write-Error (
        "Clock Rhythm $ReleaseTier release evidence is incomplete:`n- " +
        ($failures -join "`n- ")
    )
}

Write-Output "Clock Rhythm $ReleaseTier release evidence is complete."
