#Requires -Version 5.1
<#
.SYNOPSIS
    Syncs official Salesforce skills from forcedotcom/sf-skills into .cursor/skills.

.DESCRIPTION
    Uses a sparse git clone (skills/ only) to avoid Windows path-length issues with
    upstream samples/. Mirrors content into the Cursor plugin skills directory and
    updates skills-lock.json plus plugin manifest version metadata.

.PARAMETER Ref
    Git ref to sync: branch, tag, or commit (default: main).

.PARAMETER Force
    Delete the vendor clone and re-fetch from scratch.

.EXAMPLE
    .\scripts\sync-skills.ps1

.EXAMPLE
    .\scripts\sync-skills.ps1 -Ref 1.30.0

.EXAMPLE
    .\scripts\sync-skills.ps1 -Force
#>
[CmdletBinding()]
param(
    [string]$Ref = "main",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$VendorDir = Join-Path $RepoRoot ".vendor\sf-skills"
$TargetDir = Join-Path $RepoRoot ".cursor\skills"
$LockFile = Join-Path $RepoRoot "skills-lock.json"
$PluginJson = Join-Path $RepoRoot ".cursor-plugin\plugin.json"
$MarketplaceJson = Join-Path $RepoRoot ".cursor-plugin\marketplace.json"
$UpstreamUrl = "https://github.com/forcedotcom/sf-skills.git"

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Ensure-GitAvailable {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is required but was not found on PATH."
    }
}

function Reset-VendorClone {
    if (Test-Path $VendorDir) {
        Write-Step "Removing existing vendor clone at $VendorDir"
        Remove-Item -LiteralPath $VendorDir -Recurse -Force
    }
}

function Initialize-VendorClone {
    Write-Step "Cloning $UpstreamUrl (sparse: skills/)"
    $vendorParent = Split-Path $VendorDir -Parent
    if (-not (Test-Path $vendorParent)) {
        New-Item -ItemType Directory -Path $vendorParent -Force | Out-Null
    }

    git clone --depth 1 --filter=blob:none --sparse $UpstreamUrl $VendorDir | Out-Null
    Push-Location $VendorDir
    try {
        git sparse-checkout set skills | Out-Null
        if ($Ref -ne "main") {
            git fetch --depth 1 origin $Ref | Out-Null
            git checkout $Ref | Out-Null
        }
    }
    finally {
        Pop-Location
    }
}

function Update-VendorClone {
    Push-Location $VendorDir
    try {
        Write-Step "Fetching ref '$Ref' from upstream"
        git fetch --depth 1 origin $Ref | Out-Null
        git checkout $Ref | Out-Null
        git sparse-checkout set skills | Out-Null
    }
    finally {
        Pop-Location
    }
}

function Get-UpstreamVersion {
    Push-Location $VendorDir
    try {
        $raw = git show "HEAD:package.json" 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($raw)) {
            return "unknown"
        }
        $packageJson = $raw | ConvertFrom-Json
        return [string]$packageJson.version
    }
    finally {
        Pop-Location
    }
}

function Get-JsonFromFile([string]$Path) {
    if (-not (Test-Path $Path)) {
        return $null
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Set-JsonFile([string]$Path, $Object) {
    $json = $Object | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}

function Sync-SkillDirectories {
    $sourceSkills = Join-Path $VendorDir "skills"
    if (-not (Test-Path $sourceSkills)) {
        throw "Upstream skills directory not found at $sourceSkills"
    }

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    Write-Step "Mirroring skills into $TargetDir"
    $robocopyArgs = @(
        $sourceSkills,
        $TargetDir,
        "/MIR",
        "/NFL",
        "/NDL",
        "/NJH",
        "/NJS",
        "/NC",
        "/NS",
        "/NP"
    )
    & robocopy @robocopyArgs | Out-Null
    $exitCode = $LASTEXITCODE
    if ($exitCode -gt 7) {
        throw "robocopy failed with exit code $exitCode"
    }
}

function Get-SkillNames {
    param([string]$SkillsRoot)

    if (-not (Test-Path $SkillsRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $SkillsRoot -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
            Select-Object -ExpandProperty Name |
            Sort-Object
    )
}

function Update-PluginVersion([string]$Version) {
    $plugin = Get-JsonFromFile $PluginJson
    if ($null -eq $plugin) {
        throw "Missing plugin manifest at $PluginJson"
    }

    $plugin.version = $Version
    Set-JsonFile $PluginJson $plugin

    $marketplace = Get-JsonFromFile $MarketplaceJson
    if ($null -ne $marketplace -and $null -ne $marketplace.metadata) {
        $marketplace.metadata.version = $Version
        Set-JsonFile $MarketplaceJson $marketplace
    }
}

function Write-LockFile {
    param(
        [string]$Commit,
        [string]$Version,
        [string[]]$Skills
    )

    $lock = [ordered]@{
        source      = "https://github.com/forcedotcom/sf-skills"
        ref         = $Ref
        commit      = $Commit
        version     = $Version
        syncedAt    = (Get-Date).ToUniversalTime().ToString("o")
        skillCount  = $Skills.Count
        skills      = $Skills
    }

    Set-JsonFile $LockFile $lock
}

Ensure-GitAvailable

if ($Force -or -not (Test-Path (Join-Path $VendorDir ".git"))) {
    Reset-VendorClone
    Initialize-VendorClone
}
else {
    Update-VendorClone
}

Push-Location $VendorDir
try {
    $commit = (git rev-parse HEAD).Trim()
    $version = Get-UpstreamVersion
}
finally {
    Pop-Location
}

Sync-SkillDirectories
$skillNames = Get-SkillNames -SkillsRoot $TargetDir
Update-PluginVersion -Version $version
Write-LockFile -Commit $commit -Version $version -Skills $skillNames

Write-Host ""
Write-Host "Sync complete." -ForegroundColor Green
Write-Host "  Version : $version"
Write-Host "  Commit  : $commit"
Write-Host "  Ref     : $Ref"
Write-Host "  Skills  : $($skillNames.Count)"
Write-Host "  Lock    : $LockFile"
