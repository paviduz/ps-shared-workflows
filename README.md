# ps-shared-workflows

Reusable GitHub Actions workflows for PowerShell code quality enforcement.

## Workflows

### `ps-quality-gate.yml`

Runs two parallel jobs against any PowerShell repository:

| Job | What it runs | Fail condition |
| --- | --- | --- |
| `static-analysis` | `Invoke-ScriptAnalyzer` + security rule scan | Any `Error` finding; optionally `Warning` |
| `pester-tests` | `Invoke-Pester` v5 | Any failing test |

## Usage

Add a workflow file to your repository:

```yaml
# .github/workflows/ps-quality.yml
name: PowerShell Quality Gate

on:
  push:
    branches: [main]
    paths: ['**/*.ps1', '**/*.psm1', '**/*.psd1']
  pull_request:
    paths: ['**/*.ps1', '**/*.psm1', '**/*.psd1']

jobs:
  ps-quality:
    uses: pavid/ps-shared-workflows/.github/workflows/ps-quality-gate.yml@main
    with:
      ps-path: './src'
      test-path: './tests'
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `ps-path` | `.` | Path to PS files or directory to analyse |
| `settings-path` | `PSScriptAnalyzerSettings.psd1` | Repo-relative path to your settings file |
| `test-path` | _(empty)_ | Path to Pester tests. Omit to skip testing stage |
| `fail-on-warning` | `false` | Treat `Warning` findings as failures |
| `pester-verbosity` | `Normal` | Pester output level: Minimal, Normal, Detailed, Diagnostic |
| `runner` | `ubuntu-latest` | GitHub-hosted runner image |

## Settings resolution

The workflow resolves settings in this priority order:

1. Calling repo's `PSScriptAnalyzerSettings.psd1` (or path from `settings-path` input)
2. `defaults/PSScriptAnalyzerSettings.psd1` in this repository
3. PSScriptAnalyzer built-in defaults (Error + Warning severity)

To configure your own rules, copy
`defaults/PSScriptAnalyzerSettings.psd1` to your repository root and edit it.
A full annotated template is also available in
[`pavid/Homelab-Agent-Platform-Plan`](https://github.com/pavid/Homelab-Agent-Platform-Plan)
at `.github/skills/ps-quality-pipeline/templates/PSScriptAnalyzerSettings.psd1`.

## Relationship to the PS agent team

This workflow automates the deterministic stages of the five-stage quality pipeline
defined in `pavid/Homelab-Agent-Platform-Plan`:

| Pipeline stage | Automated here | Agent (interactive) |
| --- | --- | --- |
| 1 — Static analysis | `static-analysis` job | `ps-reviewer` |
| 2 — Security audit (rule-based) | `static-analysis` job | `ps-auditor` |
| 3 — Refactor | No | `ps-refactorer` |
| 4 — Tests | `pester-tests` job | `ps-tester` |
| 5 — Documentation | No | `ps-documenter` |

Stages 3 and 5 require an LLM and are handled by the agent team, not CI.
