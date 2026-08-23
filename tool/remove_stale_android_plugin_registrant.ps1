[CmdletBinding()]
param(
    [string]$RepositoryRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot '..')
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string]$resolvedRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
[string]$expectedDirectory = [System.IO.Path]::GetFullPath(
    (Join-Path $resolvedRoot 'android\app\src\main\java\io\flutter\plugins')
)
[string]$registrantPath = [System.IO.Path]::GetFullPath(
    (Join-Path $expectedDirectory 'GeneratedPluginRegistrant.java')
)
if ((Split-Path -Parent $registrantPath) -ne $expectedDirectory) {
    throw "Refusing unsafe Android plugin registrant cleanup: $registrantPath"
}
if (Test-Path -LiteralPath $registrantPath -PathType Leaf) {
    Remove-Item -LiteralPath $registrantPath -Force
    Write-Output "Removed generated Android plugin registrant: $registrantPath"
}
