#Requires -Version 7.0

<#
.SYNOPSIS
    Verifies every @path import in a repo's Claude Code memory file resolves
    to a real file.

.DESCRIPTION
    Claude Code silently skips an @import whose target doesn't exist — no
    error, no warning, it just doesn't load. That's exactly the failure mode
    that let a wrong relative-path depth (one @import written for a
    subdirectory that actually needed an extra `../`) go unnoticed during the
    AGENTS.md sync work this checks for. This script catches that class of
    bug in CI instead of relying on someone noticing missing context later.

    Checks CLAUDE.md at repo root, or .claude/CLAUDE.md if that's where a
    repo's Claude Code file lives instead (homelab-infra's generated-content
    pipeline uses the latter). Skips fenced code blocks and inline code spans
    per Claude Code's own import-parsing rules, and ignores `@` characters
    that aren't at the start of a line or preceded by whitespace (so email
    addresses in prose aren't mistaken for imports).

.PARAMETER RepoRoot
    Root of the repo to check. Defaults to the current directory.
#>

param(
    [string]$RepoRoot = '.'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ClaudeImports {
    param([string]$FilePath)

    $imports = [System.Collections.Generic.List[string]]::new()
    $inFence = $false

    foreach ($line in Get-Content -Path $FilePath) {
        if ($line -match '^\s*```') {
            $inFence = -not $inFence
            continue
        }
        if ($inFence) { continue }

        # Strip inline code spans (`...`) — imports inside them are literal text, not real imports.
        $stripped = [regex]::Replace($line, '`[^`]*`', '')

        foreach ($m in [regex]::Matches($stripped, '(?:^|(?<=\s))@(\S+)')) {
            $imports.Add($m.Groups[1].Value)
        }
    }

    return $imports
}

$candidates = @(
    @('CLAUDE.md', '.claude/CLAUDE.md') |
        ForEach-Object { Join-Path $RepoRoot $_ } |
        Where-Object { Test-Path $_ }
)

if ($candidates.Count -eq 0) {
    Write-Host "No CLAUDE.md or .claude/CLAUDE.md found under $RepoRoot — nothing to check."
    exit 0
}

$broken = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($claudeFile in $candidates) {
    $fileDir = Split-Path -Parent (Resolve-Path $claudeFile)
    foreach ($importPath in (Get-ClaudeImports -FilePath $claudeFile)) {
        $resolved = Join-Path $fileDir $importPath
        if (-not (Test-Path $resolved)) {
            $broken.Add([pscustomobject]@{
                File     = $claudeFile
                Import   = $importPath
                Resolved = $resolved
            })
        }
    }
}

if ($broken.Count -gt 0) {
    foreach ($b in $broken) {
        Write-Host "::error file=$($b.File)::Broken @import '$($b.Import)' — resolved path does not exist: $($b.Resolved)"
    }
    throw "$($broken.Count) broken @import(s) found."
}

Write-Host "OK: all @imports resolve in $($candidates -join ', ')"
